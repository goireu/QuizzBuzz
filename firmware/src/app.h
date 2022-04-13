#include <zephyr.h>
#include <sys/printk.h>

//#define DEBUG

bool button_init();

bool ble_init();
void ble_button_notify();
void ble_battery_notify(uint8_t centivolts);

#define BATTERY_SAMPLE_INTERVAL 300 // 30s
bool battery_init(void);
void battery_process(void);
int battery_sample(void); // Returns value in mV or negative value for errors

#define LED_BLINK_INTERVAL  5 // 500ms
#define LED_BLINK_CYCLES    5 // 5 seconds total
bool led_init(void);
void led_activate(unsigned char cycles);
void led_process(void);
