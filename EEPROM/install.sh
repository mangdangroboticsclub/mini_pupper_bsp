#!/bin/bash
# Install EEPROM driver
#

set -e

# Clean up old Jammy overlay if upgrading in-place
sudo rm -f /boot/firmware/overlays/i2c3.dtbo
if grep -q "^dtoverlay=i2c3$" /boot/firmware/config.txt 2>/dev/null; then
    sudo sed -i "/^dtoverlay=i2c3$/d" /boot/firmware/config.txt
fi

dtc -@ -I dts -O dtb -o mini-pupper-eeprom.dtbo mini-pupper-eeprom-overlay.dts
sudo cp mini-pupper-eeprom.dtbo /boot/firmware/overlays/

grep -q '^dtoverlay=mini-pupper-eeprom$' /boot/firmware/config.txt || \
    echo 'dtoverlay=mini-pupper-eeprom' | sudo tee -a /boot/firmware/config.txt > /dev/null
