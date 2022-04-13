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

void main(void)
{
	if (usb_enable(NULL)) {
		return;
	}
	printk("USB initialized\n");

#ifdef DEBUG
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

	while (1)
	{
		battery_process();
		led_process();

		// Get back to sleep for 100ms
		k_sleep(K_MSEC(100));
	}
}
