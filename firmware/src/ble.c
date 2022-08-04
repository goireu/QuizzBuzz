#include "app.h"

#include <sys/byteorder.h>

#include <bluetooth/bluetooth.h>
#include <bluetooth/hci.h>
#include <bluetooth/hci_vs.h>
#include <bluetooth/conn.h>
#include <bluetooth/uuid.h>
#include <bluetooth/gatt.h>
#include <bluetooth/services/bas.h>

static struct bt_conn *default_conn = NULL;
static uint16_t default_conn_handle;
static void get_tx_power(uint8_t handle_type, uint16_t handle, int8_t *tx_pwr_lvl);
static void set_tx_power(uint8_t handle_type, uint16_t handle, int8_t tx_pwr_lvl);

#define MYBT_UUID_BTN_VAL			0x4242 // Custom service ID
#define MYBT_UUID_BUTTON_PRESSED	0x4243 // Custom characteristic ID
#define MYBT_UUID_LED_ACTIVATE		0x4244 // Custom characteristic ID

static const struct bt_data ad[] = {
	BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
	BT_DATA_BYTES(BT_DATA_UUID16_ALL,
		      BT_UUID_16_ENCODE(MYBT_UUID_BTN_VAL),
		      BT_UUID_16_ENCODE(BT_UUID_BAS_VAL)
			  )
};

static bool ble_button_notify_enabled = false;
static void ble_button_ccc_cfg_changed(const struct bt_gatt_attr *attr,
				       uint16_t value)
{
	ARG_UNUSED(attr);
	ble_button_notify_enabled = (value == BT_GATT_CCC_NOTIFY);
	printk("[BLE] Button notifications %s\n", ble_button_notify_enabled ? "enabled" : "disabled");
}

static ssize_t ble_button_read_level(struct bt_conn *conn,
			       const struct bt_gatt_attr *attr, void *buf,
			       uint16_t len, uint16_t offset)
{
	printk("[BLE] Button level was read\n");
	return bt_gatt_attr_read(conn, attr, buf, len, offset, NULL, 0);
}

ssize_t ble_led_activate(struct bt_conn *conn,
			       const struct bt_gatt_attr *attr, const void *buf,
			       uint16_t len, uint16_t offset, uint8_t flags)
{
	printk("[BLE] Led was activated\n");
	if (len < 1)
		led_activate(LED_BLINK_CYCLES_DFLT);
	else
	{
		unsigned char *val = (unsigned char *)buf;
		led_activate(val[0]);
	}
	return len;
}

BT_GATT_SERVICE_DEFINE(ble_button_svc,
	BT_GATT_PRIMARY_SERVICE(BT_UUID_DECLARE_16(MYBT_UUID_BTN_VAL)),
	BT_GATT_CHARACTERISTIC(BT_UUID_DECLARE_16(MYBT_UUID_BUTTON_PRESSED),
			       BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY,
			       BT_GATT_PERM_READ, ble_button_read_level, NULL,
			       NULL),
	BT_GATT_CCC(ble_button_ccc_cfg_changed,
		    BT_GATT_PERM_READ | BT_GATT_PERM_WRITE),
	BT_GATT_CHARACTERISTIC(BT_UUID_DECLARE_16(MYBT_UUID_LED_ACTIVATE),
			       BT_GATT_CHRC_WRITE | BT_GATT_CHRC_WRITE_WITHOUT_RESP,
			       BT_GATT_PERM_WRITE, NULL, ble_led_activate,
			       NULL),
);

void ble_button_notify()
{
	int rc;
	if (ble_button_notify_enabled) {
		printk("[BLE] Notifying new button value\n");
		rc = bt_gatt_notify(NULL, &ble_button_svc.attrs[1], NULL, 0);
		if (rc && rc != -ENOTCONN)
			printk("[BLE] Failed to send button status notification\n");
	}
}

// Simulate battery values
void ble_battery_notify(uint8_t centivolts)
{
	bt_bas_set_battery_level(centivolts);
}

// Catch connect/disconnect events
static bool _ble_is_connected = false;
bool ble_is_connected(void)
{
	return _ble_is_connected;
}
void ble_connected(struct bt_conn *conn, uint8_t err)
{
	int8_t txp;
	
	if (err)
		return;

	app_reset_keep_alive(KEEPALIVE_CONNECTED); // Reset keepalive timeout
	printk("[BLE] Connected!\n");
	_ble_is_connected = true;

	default_conn = bt_conn_ref(conn);
	int ret = bt_hci_get_conn_handle(default_conn, &default_conn_handle);
	if (ret) {
		printk("No connection handle (err %d)\n", ret);
	} else {
		/* Send first at the default selected power */
		get_tx_power(BT_HCI_VS_LL_HANDLE_TYPE_CONN, default_conn_handle, &txp);
		printk("Connection (%d) - Initial Tx Power = %d\n", default_conn_handle, txp);
		set_tx_power(BT_HCI_VS_LL_HANDLE_TYPE_CONN, default_conn_handle, 8);
		get_tx_power(BT_HCI_VS_LL_HANDLE_TYPE_CONN, default_conn_handle, &txp);
		printk("Connection (%d) - Tx Power = %d\n", default_conn_handle, txp);
	}
}
void ble_disconnected(struct bt_conn *conn, uint8_t reason)
{
	app_reset_keep_alive(KEEPALIVE_UNCONNECTED); // Reset keepalive timeout
	printk("[BLE] Disconnected!\n");
	_ble_is_connected = false;
}

static struct bt_conn_cb ble_conn_cb = {
	.connected = ble_connected,
	.disconnected = ble_disconnected
};

bool ble_init()
{
    int err;
    
	err = bt_enable(NULL);
	if (err) {
		printk("[BLE] Bluetooth init failed (err %d)\n", err);
		return false;
	}

	printk("[BLE] Bluetooth initialized\n");

	bt_conn_cb_register(&ble_conn_cb);

	err = bt_le_adv_start(BT_LE_ADV_CONN_NAME, ad, ARRAY_SIZE(ad), NULL, 0);
	if (err) {
		printk("[BLE] Advertising failed to start (err %d)\n", err);
		return false;
	}

	printk("[BLE] Advertising successfully started\n");

    return true;
}

static void set_tx_power(uint8_t handle_type, uint16_t handle, int8_t tx_pwr_lvl)
{
	struct bt_hci_cp_vs_write_tx_power_level *cp;
	struct bt_hci_rp_vs_write_tx_power_level *rp;
	struct net_buf *buf, *rsp = NULL;
	int err;

	buf = bt_hci_cmd_create(BT_HCI_OP_VS_WRITE_TX_POWER_LEVEL, sizeof(*cp));
	if (!buf) {
		printk("Unable to allocate command buffer\n");
		return;
	}

	cp = net_buf_add(buf, sizeof(*cp));
	cp->handle = sys_cpu_to_le16(handle);
	cp->handle_type = handle_type;
	cp->tx_power_level = tx_pwr_lvl;

	err = bt_hci_cmd_send_sync(BT_HCI_OP_VS_WRITE_TX_POWER_LEVEL, buf, &rsp);
	if (err) {
		uint8_t reason = rsp ?
			((struct bt_hci_rp_vs_write_tx_power_level *)
			  rsp->data)->status : 0;
		printk("Set Tx power err: %d reason 0x%02x\n", err, reason);
		return;
	}

	rp = (void *)rsp->data;
	printk("Actual Tx Power: %d\n", rp->selected_tx_power);

	net_buf_unref(rsp);
}

static void get_tx_power(uint8_t handle_type, uint16_t handle, int8_t *tx_pwr_lvl)
{
	struct bt_hci_cp_vs_read_tx_power_level *cp;
	struct bt_hci_rp_vs_read_tx_power_level *rp;
	struct net_buf *buf, *rsp = NULL;
	int err;

	*tx_pwr_lvl = 0xFF;
	buf = bt_hci_cmd_create(BT_HCI_OP_VS_READ_TX_POWER_LEVEL, sizeof(*cp));
	if (!buf) {
		printk("Unable to allocate command buffer\n");
		return;
	}

	cp = net_buf_add(buf, sizeof(*cp));
	cp->handle = sys_cpu_to_le16(handle);
	cp->handle_type = handle_type;

	err = bt_hci_cmd_send_sync(BT_HCI_OP_VS_READ_TX_POWER_LEVEL, buf, &rsp);
	if (err) {
		uint8_t reason = rsp ?
			((struct bt_hci_rp_vs_read_tx_power_level *)
			  rsp->data)->status : 0;
		printk("Read Tx power err: %d reason 0x%02x\n", err, reason);
		return;
	}

	rp = (void *)rsp->data;
	*tx_pwr_lvl = rp->tx_power_level;

	net_buf_unref(rsp);
}
