#include <zephyr.h>
#include <sys/printk.h>

// When you define this, program will wait for USB port to be opened early in firmware
//#define DEBUG

#define KEEPALIVE_UNCONNECTED   30      // 30 seconds
#define KEEPALIVE_CONNECTED     1800    // 30 minutes
void app_reset_keep_alive();
bool app_is_alive();

bool button_init(void);

bool ble_init(void);
bool ble_is_connected(void);
void ble_button_notify(void);
void ble_battery_notify(uint8_t centivolts);

#define BATTERY_SAMPLE_INTERVAL 300 // 30s
bool battery_init(void);
void battery_process(void);
int battery_sample(void); // Returns value in mV or negative value for errors

#define LED_BLINK_INTERVAL       5 // 500ms
#define LED_BLINK_CYCLES_DFLT    5 // 5 seconds total
bool led_init(void);
void led_set(bool on);
void led_activate(uint8_t cycles);
void led_process(void);
