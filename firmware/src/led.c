#include "app.h"
#include <drivers/gpio.h>

/* This is the embedded LED. */
#define LED0_NODE DT_ALIAS(led0)
#define LED0	    DT_GPIO_LABEL(LED0_NODE, gpios)
#define LED0_PIN	DT_GPIO_PIN(LED0_NODE, gpios)
#define LED0_FLAGS	DT_GPIO_FLAGS(LED0_NODE, gpios)
static const struct device *led0_dev;

/* This is the buzzer indicator LED. */
#define LED1_NODE DT_ALIAS(led1)
#define LED1	    DT_GPIO_LABEL(LED1_NODE, gpios)
#define LED1_PIN	DT_GPIO_PIN(LED1_NODE, gpios)
#define LED1_FLAGS	DT_GPIO_FLAGS(LED1_NODE, gpios)
static const struct device *led1_dev;

static unsigned int led_prescaler = 0;
static unsigned int led_blink_counter = 0;
static bool led_on = false;

bool led_init(void)
{
	int ret;

    // LED0
	led0_dev = device_get_binding(LED0);
	if (led0_dev == NULL) {
        printk("[LED] Led 0 not found\n");
		return false;
	}
	ret = gpio_pin_configure(led0_dev, LED0_PIN, GPIO_OUTPUT_ACTIVE | LED0_FLAGS);
	if (ret < 0) {
        printk("[LED] Can't configure led 0\n");
		return false;
	}
    gpio_pin_set(led0_dev, LED0_PIN, 0); // Inverted logic is handled at driver level
    printk("[LED] Configured Led 0\n");
    
    // LED1
	led1_dev = device_get_binding(LED1);
	if (led1_dev == NULL) {
        printk("[LED] Led 1 not found\n");
		return false;
	}
	ret = gpio_pin_configure(led1_dev, LED1_PIN, GPIO_OUTPUT_ACTIVE | LED1_FLAGS);
	if (ret < 0) {
        printk("[LED] Can't configure led 1\n");
		return false;
	}
    gpio_pin_set(led1_dev, LED1_PIN, 0);
    printk("[LED] Configured Led 1\n");

    return true;
}

void led_set(bool on)
{
    gpio_pin_set(led0_dev, LED0_PIN, on ? 1 : 0); // Inverted logic is handled at driver level
    gpio_pin_set(led1_dev, LED1_PIN, on ? 1 : 0);
    led_on = on;
}

void led_activate(unsigned char cycles)
{
    // Switch off instantly
    if (!cycles) {
        led_set(false);
        led_blink_counter = 0; // Stop the blinking process
    }
    // Switch on without blinking
    else if (cycles == 0xFF) {
        led_set(true);
        led_blink_counter = 0; // Stop the blinking process
    }
    // For all other values, start blinking the required time
    else {
        led_prescaler = 0; // Trigger led blinking instantly
        led_blink_counter = cycles * 2; // Let led blink
    }
}

void led_process(void)
{
    // Blink quickly while BLE is not yet paired
    if (!ble_is_connected()) {
        led_set(!led_on);
    }
    // Perform what Quizzer app told us to do
    else  {
        if (!led_prescaler) {
            led_prescaler = LED_BLINK_INTERVAL;

            if (led_blink_counter) {
                printk("LED BlINK %s\n", led_on ? "on" : "off");
                led_blink_counter--;
                led_set(!led_on);
            }
        }
        led_prescaler--;
    }
}
