#!/bin/bash
# Install EEPROM driver
#

if [ $(lsb_release -cs) == "jammy" ]; then
    cp ubuntu_22.04/* .
else
    cp ubuntu_20.04/* .
fi

set -x
make
make install

dtc i2c3.dts > i2c3.dtbo
sudo cp i2c3.dtbo /boot/firmware/overlays/
