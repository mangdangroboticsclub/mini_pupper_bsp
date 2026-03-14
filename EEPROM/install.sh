#!/bin/bash
# Install EEPROM driver
#

set -e

dtc -@ -I dts -O dtb -o mini-pupper-eeprom.dtbo mini-pupper-eeprom-overlay.dts
sudo cp mini-pupper-eeprom.dtbo /boot/firmware/overlays/

grep -q '^dtoverlay=mini-pupper-eeprom$' /boot/firmware/config.txt || \
    echo 'dtoverlay=mini-pupper-eeprom' | sudo tee -a /boot/firmware/config.txt > /dev/null
