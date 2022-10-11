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
grep -q "mini_pupper" /etc/hostname || echo "mini_pupper" | sudo tee /etc/hostname
grep -q "mini_pupper" /etc/hosts || echo "127.0.0.1	mini_pupper" | sudo tee -a /etc/hosts


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
    sudo sed -i "s/3-00500/3-00501/" $BASEDIR/Python_Module/MangDang/mini_pupper/nvram.py
fi
sudo rm -rf /var/lib/mini_pupper_bsp
sudo cp -r $BASEDIR/Display /var/lib/mini_pupper_bsp
sudo pip install $BASEDIR/Python_Module

### Make pwm sysfs and nvmem work for non-root users
### reference: https://github.com/raspberrypi/linux/issues/1983
### reference: https://github.com/bitula/mini_pupper-dev/blob/main/scripts/mini_pupper.sh
getent group gpio || sudo groupadd gpio && sudo gpasswd -a $(whoami) gpio
getent group dialout || sudo groupadd dialout && sudo gpasswd -a $(whoami) dialout
getent group spi || sudo groupadd spi && sudo gpasswd -a $(whoami) spi
sudo tee /etc/udev/rules.d/99-mini_pupper-pwm.rules << EOF > /dev/null
KERNEL=="pwmchip0", SUBSYSTEM=="pwm", RUN+="/usr/lib/udev/pwm-mini_pupper.sh"
EOF
sudo tee /etc/udev/rules.d/99-mini_pupper-gpio.rules << EOF > /dev/null
KERNELS=="gpiochip0", SUBSYSTEM=="gpio", ACTION=="add", ATTR{label}=="pinctrl-bcm2711", RUN+="/usr/lib/udev/gpio-mini_pupper.sh"
KERNEL=="gpiomem", OWNER="root", GROUP="gpio", MODE="0660"
EOF
sudo tee /etc/udev/rules.d/99-mini_pupper-nvmem.rules << EOF > /dev/null
KERNEL=="3-00500", SUBSYSTEM=="nvmem", RUN+="/bin/chmod 666 /sys/bus/nvmem/devices/3-00500/nvmem"
KERNEL=="3-00501", SUBSYSTEM=="nvmem", RUN+="/bin/chmod 666 /sys/bus/nvmem/devices/3-00501/nvmem"
EOF
sudo tee /etc/udev/rules.d/99-mini_pupper-spi.rules << EOF > /dev/null
KERNEL=="spidev0.0", OWNER="root", GROUP="spi", MODE="0660"
EOF

sudo tee /usr/lib/udev/pwm-mini_pupper.sh << "EOF" > /dev/null
#!/bin/bash
for i in $(seq 0 15); do
    echo $i > /sys/class/pwm/pwmchip0/export
    echo 4000000 > /sys/class/pwm/pwmchip0/pwm$i/period
    chmod 666 /sys/class/pwm/pwmchip0/pwm$i/duty_cycle
    chmod 666 /sys/class/pwm/pwmchip0/pwm$i/enable
done
EOF
sudo chmod +x /usr/lib/udev/pwm-mini_pupper.sh

sudo tee /usr/lib/udev/gpio-mini_pupper.sh << EOF > /dev/null
#!/bin/bash
# Board power
echo 21 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio21/direction
chmod 666 /sys/class/gpio/gpio21/value
echo 1 > /sys/class/gpio/gpio21/value

echo 25 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio25/direction
chmod 666 /sys/class/gpio/gpio25/value
echo 1 > /sys/class/gpio/gpio25/value

# LCD power
echo 22 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio22/direction
chmod 666 /sys/class/gpio/gpio22/value
echo 1 > /sys/class/gpio/gpio22/value
EOF
sudo chmod +x /usr/lib/udev/gpio-mini_pupper.sh

sudo udevadm control --reload-rules && sudo udevadm trigger
