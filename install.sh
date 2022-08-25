#!/bin/bash

set -e

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ssid> <wifi password>"
    exit 1
fi

### Prevent starting unattended-upgrade during script execution
for TARGET_FILE in $(grep -ril "Update-Package-Lists" /etc/apt/apt.conf.d/); do
    echo Rewriting $TARGET_FILE
    sudo sed -i -e 's/Update-Package-Lists "1"/Update-Package-Lists "0"/g' -e 's/Unattended-Upgrade "1"/Unattended-Upgrade "0"/g' $TARGET_FILE
done

############################################
# wait until unattended-upgrade has finished
############################################
tmp=$(ps aux | grep unattended-upgrade | grep -v unattended-upgrade-shutdown | grep python | wc -l)
[ $tmp == "0" ] || echo "waiting for unattended-upgrade to finish"
while [ $tmp != "0" ];do
sleep 10;
echo -n "."
tmp=$(ps aux | grep unattended-upgrade | grep -v unattended-upgrade-shutdown | grep python | wc -l)
done

### Give a meaningfull hostname
echo "minipupper" | sudo tee /etc/hostname
echo "127.0.0.1	minipupper" | sudo tee -a /etc/hosts

### Setup wireless networking ( must change SSID and password )
if ! grep -q "wifis:" /etc/netplan/50-cloud-init.yaml; then
    sudo sed -i "/version: 2/d" /etc/netplan/50-cloud-init.yaml
    echo "    wifis:" | sudo tee -a /etc/netplan/50-cloud-init.yaml
    echo "        wlan0:" | sudo tee -a /etc/netplan/50-cloud-init.yaml
    echo "            access-points:" | sudo tee -a /etc/netplan/50-cloud-init.yaml
    echo "                $1:" | sudo tee -a /etc/netplan/50-cloud-init.yaml
    echo "                    password: \"$2\"" | sudo tee -a /etc/netplan/50-cloud-init.yaml
    echo "            dhcp4: true" | sudo tee -a /etc/netplan/50-cloud-init.yaml
    echo "            optional: true" | sudo tee -a /etc/netplan/50-cloud-init.yaml
    echo "    version: 2" | sudo tee -a /etc/netplan/50-cloud-init.yaml
fi

### upgrade Ubuntu and install required packages
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
sudo sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
sudo apt update
sudo apt -y upgrade
sudo apt install -y i2c-tools dpkg-dev curl python-is-python3 mpg321 python3-tk
sudo sed -i "s/pulse/alsa/" /etc/libao.conf
if [ $(lsb_release -cs) == "jammy" ]; then
    sudo sed -i "s/cards.pcm.front/cards.pcm.default/" /usr/share/alsa/alsa.conf
fi

### Install
for dir in IO_Configuration FuelGauge System EEPROM; do
    cd $BASEDIR/$dir
    ./install.sh
done

sudo sed -i "s|BASEDIR|$BASEDIR|" /etc/rc.local
sudo sed -i "s|BASEDIR|$BASEDIR|" /usr/bin/battery_monitor

### Install pip
cd /tmp
wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py

### Install LCD driver
sudo apt install -y python3-dev
sudo git config --global --add safe.directory $BASEDIR # temporary fix https://bugs.launchpad.net/devstack/+bug/1968798
if [ $(lsb_release -cs) == "jammy" ]; then
    sudo sed -i "s/3-00500/3-00501/" $BASEDIR/Python_Modules/MangDang/minipupper/Config.py
    sudo sed -i "s/3-00500/3-00501/" $BASEDIR/Python_Modules/MangDang/minipupper/calibrate_tool.py
    sudo sed -i "s/3-00500/3-00501/" $BASEDIR/Python_Modules/MangDang/minipupper/calibrate_servos.py
fi
sudo pip install $BASEDIR/Python_Modules
