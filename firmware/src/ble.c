#include "app.h"

#include <bluetooth/bluetooth.h>
#include <bluetooth/hci.h>
#include <bluetooth/conn.h>
#include <bluetooth/uuid.h>
#include <bluetooth/gatt.h>
#include <bluetooth/services/bas.h>

#define MYBT_UUID_BTN_VAL			0x4242 // Custom service ID
#define MYBT_UUID_BUTTON_PRESSED	0x4243 // Custom characteristic ID
#define MYBT_UUID_LED_ACTIVATE		0x4244 // Custom characteristic ID

static const struct bt_data ad[] = {
	BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
	BT_DATA_BYTES(BT_DATA_UUID16_ALL,
		      BT_UUID_16_ENCODE(MYBT_UUID_BTN_VAL),
		      BT_UUID_16_ENCODE(BT_UUID_BAS_VAL),
//		      BT_UUID_16_ENCODE(BT_UUID_DIS_VAL)
			  )
};

static bool ble_button_notify_enabled = false;
static void ble_button_ccc_cfg_changed(const struct bt_gatt_attr *attr,
				       uint16_t value)
{
	ARG_UNUSED(attr);
	ble_button_notify_enabled = (value == BT_GATT_CCC_NOTIFY);
	printk("[BLE] Button notifications %s", ble_button_notify_enabled ? "enabled" : "disabled");
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
		led_activate(LED_BLINK_CYCLES);
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
			printk("[BLE] Failed to send button status notification");
	}
}

// Simulate battery values
void ble_battery_notify(uint8_t centivolts)
{
	bt_bas_set_battery_level(centivolts);
}

static void ble_auth_cancel(struct bt_conn *conn)
{
	char addr[BT_ADDR_LE_STR_LEN];

	bt_addr_le_to_str(bt_conn_get_dst(conn), addr, sizeof(addr));
	printk("[BLE] Pairing canceled: %s\n", addr);
}

static void ble_pairing_complete(struct bt_conn *conn, bool bonded)
{
	char addr[BT_ADDR_LE_STR_LEN];

	bt_addr_le_to_str(bt_conn_get_dst(conn), addr, sizeof(addr));
	printk("[BLE] Pairing complete: %s\n", addr);
}

static struct bt_conn_auth_cb ble_auth_cb_display = {
	.cancel = ble_auth_cancel,
	.pairing_complete = ble_pairing_complete,
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

	err = bt_le_adv_start(BT_LE_ADV_CONN_NAME, ad, ARRAY_SIZE(ad), NULL, 0);
	if (err) {
		printk("[BLE] Advertising failed to start (err %d)\n", err);
		return false;
	}

	printk("[BLE] Advertising successfully started\n");

	err = bt_conn_auth_cb_register(&ble_auth_cb_display);
	if (err) {
		printk("[BLE] Failed to register callbacks (err %d)\n", err);
		return false;
	}

    return true;
}
