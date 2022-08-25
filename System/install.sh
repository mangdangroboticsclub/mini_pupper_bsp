#!/bin/bash
# The command script to init system for mini pupper 
set -x
sudo cp 20auto-upgrades /etc/apt/apt.conf.d/
sudo apt-get remove -y ubuntu-release-upgrader-core
sudo chmod 440 sudoers
sudo cp sudoers  /etc/
sudo cp rc.local /etc/
if [ $(lsb_release -cs) == "jammy" ]; then
    sudo sed -i "s/3-00500/3-00501/" /etc/rc.local
fi
sudo cp rc-local.service /lib/systemd/system/
sudo systemctl enable rc-local
