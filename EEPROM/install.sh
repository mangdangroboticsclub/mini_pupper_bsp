#!/bin/bash
# Install EEPROM driver
#

dtc i2c3.dts > i2c3.dtbo
sudo cp i2c3.dtbo /boot/firmware/overlays/
