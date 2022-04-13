#include "app.h"
#include <drivers/gpio.h>

/*
 * Get button configuration from the devicetree sw0 alias. This is mandatory.
 */
#define SW0_NODE	DT_ALIAS(sw0)	// This is the embedded pushbutton
#define SW1_NODE	DT_ALIAS(sw1)	// This is the buzzer wired on P1.00
#if !DT_NODE_HAS_STATUS(SW0_NODE, okay)
#error "Unsupported board: sw0 devicetree alias is not defined"
#endif
#if !DT_NODE_HAS_STATUS(SW1_NODE, okay)
#error "Unsupported board: sw1 devicetree alias is not defined"
#endif
static const struct gpio_dt_spec button0 = GPIO_DT_SPEC_GET_OR(SW0_NODE, gpios,
							      {0});
static const struct gpio_dt_spec button1 = GPIO_DT_SPEC_GET_OR(SW1_NODE, gpios,
							      {0});
static struct gpio_callback button0_cb_data;
static struct gpio_callback button1_cb_data;

void ble_button_notify();
void button_pressed(const struct device *dev, struct gpio_callback *cb,
		    uint32_t pins)
{
	printk("[BTN] Button pressed\n");
	ble_button_notify();
}

bool button_init()
{
	int ret;

	if (!device_is_ready(button0.port)) {
		printk("[BTN] Error: button device %s is not ready\n", button0.port->name);
		return false;
	}
	if (!device_is_ready(button1.port)) {
		printk("[BTN] Error: button device %s is not ready\n", button1.port->name);
		return false;
	}

	ret = gpio_pin_configure_dt(&button0, GPIO_INPUT);
	if (ret != 0) {
		printk("[BTN] Error %d: failed to configure %s pin %d\n", ret, button0.port->name, button0.pin);
		return false;
	}
	ret = gpio_pin_configure_dt(&button1, GPIO_INPUT);
	if (ret != 0) {
		printk("[BTN] Error %d: failed to configure %s pin %d\n", ret, button1.port->name, button1.pin);
		return false;
	}

	ret = gpio_pin_interrupt_configure_dt(&button0, GPIO_INT_EDGE_TO_ACTIVE);
	if (ret != 0) {
		printk("[BTN] Error %d: failed to configure interrupt on %s pin %d\n", ret, button0.port->name, button0.pin);
		return false;
	}
	ret = gpio_pin_interrupt_configure_dt(&button1, GPIO_INT_EDGE_TO_ACTIVE);
	if (ret != 0) {
		printk("[BTN] Error %d: failed to configure interrupt on %s pin %d\n", ret, button1.port->name, button1.pin);
		return false;
	}

	gpio_init_callback(&button0_cb_data, button_pressed, BIT(button0.pin));
	gpio_init_callback(&button1_cb_data, button_pressed, BIT(button1.pin));
	gpio_add_callback(button0.port, &button0_cb_data);
	gpio_add_callback(button1.port, &button1_cb_data);
	printk("[BTN] Set up button at %s pin %d\n", button0.port->name, button0.pin);
	printk("[BTN] Set up button at %s pin %d\n", button1.port->name, button1.pin);
    return true;
}
