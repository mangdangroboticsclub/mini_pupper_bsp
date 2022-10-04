#!/bin/bash

set -e

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

sudo apt-get install -y dkms

cd $BASEDIR/FuelGauge
sudo mkdir -p /usr/src/max1720x_battery-1.0
sudo cp Makefile /usr/src/max1720x_battery-1.0
sudo cp max1720x_battery.c /usr/src/max1720x_battery-1.0/
sudo cp dkms.conf /usr/src/max1720x_battery-1.0/

sudo dkms add -m max1720x_battery -v 1.0
sudo dkms build -m max1720x_battery -v 1.0
sudo dkms install -m max1720x_battery -v 1.0

cd $BASEDIR/EEPROM
sudo mkdir -p /usr/src/at24-1.0
sudo cp Makefile /usr/src/at24-1.0
if [ $(lsb_release -cs) == "jammy" ]; then
    sudo cp ubuntu_22.04/* /usr/src/at24-1.0
else
    sudo cp ubuntu_20.04/* /usr/src/at24-1.0
fi
sudo cp dkms.conf /usr/src/at24-1.0/

sudo dkms add -m at24 -v 1.0
sudo dkms build -m at24 -v 1.0
sudo dkms install -m at24 -v 1.0
