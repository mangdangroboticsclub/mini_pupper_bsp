#!/bin/bash

set -e

# Remove orphan DKMS entries not part of this BSP
sudo dkms remove -m rpi-i2s-audio -v 1.0 --all 2>/dev/null || true

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Use inherited UBUNTU_CODENAME if set, otherwise detect
UBUNTU_CODENAME=${UBUNTU_CODENAME:-$(lsb_release -cs)}

sudo apt-get install -y dkms

cd $BASEDIR/EEPROM
if [ "$UBUNTU_CODENAME" == "noble" ]; then
    echo "Skipping EEPROM at24 DKMS on Ubuntu 24.04; using kernel built-in at24 driver"
else
    sudo mkdir -p /usr/src/at24-1.0
    sudo cp Makefile /usr/src/at24-1.0
    if [ "$UBUNTU_CODENAME" == "jammy" ]; then
        sudo cp ubuntu_22.04/* /usr/src/at24-1.0
    else
        sudo cp ubuntu_20.04/* /usr/src/at24-1.0
    fi
    sudo cp dkms.conf /usr/src/at24-1.0/

    sudo dkms add -m at24 -v 1.0
    sudo dkms build -m at24 -v 1.0
    sudo dkms install -m at24 -v 1.0
fi

cd $BASEDIR/PWMController
sudo mkdir -p /usr/src/pwm_pca9685-1.0
sudo cp Makefile /usr/src/pwm_pca9685-1.0
sudo cp pwm_pca9685.c /usr/src/pwm_pca9685-1.0/
sudo cp dkms.conf /usr/src/pwm_pca9685-1.0/

sudo dkms add -m pwm_pca9685 -v 1.0
sudo dkms build -m pwm_pca9685 -v 1.0
sudo dkms install -m pwm_pca9685 -v 1.0
