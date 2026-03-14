#!/bin/bash

UBUNTU_CODENAME=${UBUNTU_CODENAME:-$(lsb_release -cs)}
if [ "$UBUNTU_CODENAME" == "jammy" ] || [ "$UBUNTU_CODENAME" == "noble" ]; then
    sudo cp ubuntu_22.04/config.txt /boot/firmware/ -f
else
    sudo cp ubuntu_20.04/syscfg.txt /boot/firmware/ -f
fi

