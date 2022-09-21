#!/bin/bash

set -e

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### Fix audio device
AUDIO_DEVICE=$(cat /proc/asound/pcm | grep Headphones | sed -E "s/^([0-9].)-([0-9].):.*/hw:\1,\2/g")
for f in test.sh FuelGauge/battery_monitor System/rc.local; do
    if ! grep -q "mpg123 -a" $BASEDIR/$f; then
        sed -i -e "s/mpg123/mpg123 -a ${AUDIO_DEVICE:-hw:0,1}/g" $BASEDIR/$f
    fi
done
if ! grep -q "mpg123 -a" /etc/rc.local; then
    sudo sed -i -e "s/mpg123/mpg123 -a ${AUDIO_DEVICE:-hw:0,1}/g" /etc/rc.local
fi

### Reinstall kernel modules
for dir in FuelGauge EEPROM; do
    cd $BASEDIR/$dir
    ./install.sh
done
