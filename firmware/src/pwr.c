#include "app.h"
#include <drivers/gpio.h>

/*
 * Get power switch configuration from the devicetree psw0 alias. This is mandatory.
 */
#define PSW0_NODE	DT_ALIAS(psw0)
#if !DT_NODE_HAS_STATUS(PSW0_NODE, okay)
#error "Unsupported board: psw0 devicetree alias is not defined"
#endif
static const struct gpio_dt_spec psw0 = GPIO_DT_SPEC_GET_OR(PSW0_NODE, gpios, {0});

bool pwr_init(void)
{
	int ret;

	if (!device_is_ready(psw0.port)) {
		printk("[PWR] Error: button device %s is not ready\n", psw0.port->name);
		return false;
	}

	ret = gpio_pin_configure_dt(&psw0, GPIO_OUTPUT);
	if (ret != 0) {
		printk("[PWR] Error %d: failed to configure %s pin %d\n", ret, psw0.port->name, psw0.pin);
		return false;
	}
    ret = gpio_pin_set(psw0.port, psw0.pin, GPIO_OUTPUT_HIGH);
	if (ret != 0) {
		printk("[PWR] Error %d: failed to output high on %s pin %d\n", ret, psw0.port->name, psw0.pin);
		return false;
	}

	printk("[PWR] Set up power switch at %s pin %d\n", psw0.port->name, psw0.pin);
    return true;
}

bool pwr_down()
{
    int ret = gpio_pin_configure_dt(&psw0, GPIO_INPUT);
    if (ret != 0) {
		printk("[PWR] Error %d: failed to output LOW on %s pin %d\n", ret, psw0.port->name, psw0.pin);
		return false;
	}
    return true;
}
