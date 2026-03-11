#!/usr/bin/env sh
# Install pca9685 driver
#

set -x
dtc i2c-pwm-pca9685a.dts > i2c-pwm-pca9685a.dtbo
sudo cp i2c-pwm-pca9685a.dtbo /boot/firmware/overlays/
make
make install
