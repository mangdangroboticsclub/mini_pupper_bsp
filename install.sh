#!/bin/bash

set -e

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


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


### upgrade Ubuntu and install required packages
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
sudo sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
sudo apt update
sudo apt -y upgrade
sudo apt install -y i2c-tools dpkg-dev curl python-is-python3 mpg321 python3-tk openssh-server
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

### Make pwm sysfs and nvmem work for non-root users
### reference: https://github.com/raspberrypi/linux/issues/1983
getent group gpio || sudo groupadd gpio && sudo gpasswd -a $(whoami) gpio
getent group dialout || sudo groupadd dialout && sudo gpasswd -a $(whoami) dialout
sudo tee /etc/udev/rules.d/99-minipupper-pwm.rules << EOF > /dev/null
SUBSYSTEM=="pwm*", PROGRAM="/bin/sh -c '\
        chown -R root:gpio /sys/class/pwm && chmod -R 770 /sys/class/pwm;\
        chown -R root:gpio /sys/class/pwm/pwmchip0/pwm*/duty_cycle && chmod -R 770 /sys/class/pwm/pwmchip0/pwm*/duty_cycle'"
EOF

if [ $(lsb_release -cs) == "jammy" ]; then
sudo tee /etc/udev/rules.d/99-minipupper-nvmem.rules << EOF > /dev/null
SUBSYSTEM=="nvmem", DEVPATH=="*0-00501", RUN+="/bin/chown root:gpio /sys$env{DEVPATH}/nvmem", RUN+="/bin/chmod 660 /sys$env{DEVPATH}/nvmem"
EOF
else
sudo tee /etc/udev/rules.d/99-minipupper-nvmem.rules << EOF > /dev/null
SUBSYSTEM=="nvmem", DEVPATH=="*0-00500", RUN+="/bin/chown root:gpio /sys$env{DEVPATH}/nvmem", RUN+="/bin/chmod 660 /sys$env{DEVPATH}/nvmem"
EOF
fi
sudo udevadm control --reload-rules && sudo udevadm trigger
