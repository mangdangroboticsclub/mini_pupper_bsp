#!/bin/bash

if [ $(lsb_release -cs) == "jammy" ]; then
    sudo cp ubuntu_22.04/config.txt /boot/firmware/ -f
else
    sudo cp ubuntu_20.04/syscfg.txt /boot/firmware/ -f
fi

