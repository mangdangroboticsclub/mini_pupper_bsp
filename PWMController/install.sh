#!/usr/bin/env sh
# Install pca9685 driver
#

set -x
dtc i2c-pwm-pca9685a.dts > i2c-pwm-pca9685a.dtbo
sudo cp i2c-pwm-pca9685a.dtbo /boot/firmware/overlays/
# Note: Module compilation is handled by DKMS in prepare_dkms.sh
# Skip local make commands to avoid conflicts with DKMS-installed modules
echo "PWM controller device tree overlay installed. Driver compiled via DKMS."

