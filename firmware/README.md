# QuizzBuzz firmware for nRF52840 Dongle

## Requirements
- nRF Connect SDK v1.9.1 + toolchain (set up from Toolchain Manager)

## How to build and flash
- Open a terminal from Toolchain manager
- make a symlink from firmware folder to <SDK root>/projects/quizzbuzzfw
- build with `west build -b nrf52840dongle_nrf52840 projects/quizzbuzzfw/ --pristine` (use `--pristine` only the first time)
- put dongle into flash mode (use right angled button, led should dim on/off)
- flash with `nrfutil pkg generate --hw-version 52 --sd-req=0x00 --application build/zephyr/zephyr.hex --application-version 1 app.zip && nrfutil dfu usb-serial -pkg app.zip -p /dev/tty.usbmodemXXXXXXXXXXXXX` (file changes for each dongle)
