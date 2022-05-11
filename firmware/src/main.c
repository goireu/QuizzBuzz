/*
 * Copyright (c) 2016 Intel Corporation.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "app.h"
#include "battery.h"

#include <usb/usb_device.h>
#include <drivers/uart.h>

BUILD_ASSERT(DT_NODE_HAS_COMPAT(DT_CHOSEN(zephyr_console), zephyr_cdc_acm_uart),
	     "Console device is not ACM CDC UART device");

void app_process();

void main(void)
{
	if (!pwr_init())
		NVIC_SystemReset();

#ifdef DEBUG
	if (usb_enable(NULL)) {
		return;
	}
	printk("[MAIN] USB initialized\n");

	// Wait for debug port to be opened
	const struct device *dev = DEVICE_DT_GET(DT_CHOSEN(zephyr_console));
	uint32_t dtr = 0;
	while (!dtr) {
		uart_line_ctrl_get(dev, UART_LINE_CTRL_DTR, &dtr);
		k_sleep(K_MSEC(100));
	}
#endif

	if (!ble_init())
		NVIC_SystemReset();
	if (!button_init())
		NVIC_SystemReset();
	if (!led_init())
		NVIC_SystemReset();
	if (!battery_init())
		NVIC_SystemReset();

	while (app_is_alive())
	{
		app_process();
		battery_process();
		led_process();

		// Get back to sleep for 100ms
		k_sleep(K_MSEC(100));
	}

	printk("[MAIN] Shutting down\n");
	led_set(false);
	if (!pwr_down())
		NVIC_SystemReset();
}

static unsigned long app_timeout = KEEPALIVE_UNCONNECTED;
void app_reset_keep_alive(unsigned long timeout)
{
	app_timeout = timeout;
}

void app_process()
{
	static char prescaler = 10; // App tick is 100ms

	prescaler--;
	if (!prescaler) {
		prescaler = 10;
		if (app_timeout)
			app_timeout--;
	}
}

bool app_is_alive()
{
	return app_timeout != 0;
}
