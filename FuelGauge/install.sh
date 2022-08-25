#!/bin/bash
# Install FuelGauge driver and battery monitor daemon
#

set -x

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


make clean
make
make install

sudo cp battery_monitor /usr/bin/
sudo sed -i "s|BASEDIR|$BASEDIR/..|" /usr/bin/battery_monitor
sudo cp battery_monitor.service /lib/systemd/system/
sudo systemctl enable  battery_monitor.service

dtc i2c4.dts > i2c4.dtbo
sudo cp i2c4.dtbo /boot/firmware/overlays/
