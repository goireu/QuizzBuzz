/*
 * Copyright (c) 2018-2019 Peter Bigot Consulting, LLC
 * Copyright (c) 2019-2020 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "app.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include <init.h>
#include <drivers/adc.h>

#define ZEPHYR_USER DT_PATH(zephyr_user)

#define BATTERY_ADC_GAIN ADC_GAIN_1_6

struct divider_data
{
	const struct device *adc;
	struct adc_channel_cfg adc_cfg;
	struct adc_sequence adc_seq;
	int16_t raw;
};
static struct divider_data divider_data =
{
	.adc = DEVICE_DT_GET(DT_IO_CHANNELS_CTLR(ZEPHYR_USER)),
};

static bool battery_inited = false;
static unsigned int battery_prescaler = 0;

bool battery_init(void)
{
	struct divider_data *ddp = &divider_data;
	struct adc_sequence *asp = &ddp->adc_seq;
	struct adc_channel_cfg *accp = &ddp->adc_cfg;

	if (!device_is_ready(ddp->adc))
	{
		printk("[BAT] ADC device is not ready\n");
		return -ENOENT;
	}

	*asp = (struct adc_sequence)
	{
		.channels = BIT(0),
		.buffer = &ddp->raw,
		.buffer_size = sizeof(ddp->raw),
		.oversampling = 4,
		.calibrate = true,
		.resolution = 14,
	};

	*accp = (struct adc_channel_cfg){
		.gain = BATTERY_ADC_GAIN,
		.reference = ADC_REF_INTERNAL,
		.acquisition_time = ADC_ACQ_TIME(ADC_ACQ_TIME_MICROSECONDS, 40),
		.input_positive = SAADC_CH_PSELP_PSELP_VDD,
	};

	if (adc_channel_setup(ddp->adc, accp))
	{
		printk("[BAT] ADC setup failed\n");
		return false;
	}
	battery_inited = true;
	printk("[BAT] Battery measurement initialized\n");
	return true;
}

int battery_sample(void)
{
	int rc = -ENOENT;

	if (battery_inited)
	{
		struct divider_data *ddp = &divider_data;
		struct adc_sequence *sp = &ddp->adc_seq;

		rc = adc_read(ddp->adc, sp);
		sp->calibrate = false;
		if (rc == 0) {
			int32_t val = ddp->raw;

			adc_raw_to_millivolts(adc_ref_internal(ddp->adc),
					      ddp->adc_cfg.gain,
					      sp->resolution,
					      &val);

			rc = val;
		}
	}

	return rc;
}

void battery_process(void)
{
	int batt_mV;
	uint8_t batt_cV;

	if (!battery_prescaler)
	{
		battery_prescaler = BATTERY_SAMPLE_INTERVAL;
		// Sample battery voltage
		batt_mV = battery_sample();
		if (batt_mV > 0)
		{
			batt_cV = (uint8_t)(batt_mV / 100);
			ble_battery_notify(batt_cV);
		}
		else
			printk("Failed to read battery voltage: %d\n", batt_mV);
	}
	battery_prescaler--;
}
