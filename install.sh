#!/bin/bash

set -e

sudo apt update
# NOTE: Run 'sudo apt update && sudo apt upgrade' manually before running
# this script to ensure system packages are up to date. Performing a full
# upgrade here risks changing the running kernel mid-install, which would
# invalidate DKMS modules built in the steps below.

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### Detect Ubuntu version
UBUNTU_CODENAME=$(lsb_release -cs)
echo "Detected Ubuntu codename: $UBUNTU_CODENAME"

### Write release file
echo BUILD_DATE=\"$(date)\" > ~/mini-pupper-release
echo HARDWARE=\"$(python3 $BASEDIR/Python_Module/MangDang/mini_pupper/capabilities.py)\" >> ~/mini-pupper-release
echo MACHINE=\"$(uname -m)\" >> ~/mini-pupper-release
if [ -f /boot/firmware/user-data ]
then
    echo CLOUD_INIT_CLONE=\"$(grep clone /boot/firmware/user-data | awk -F'"' '{print $2}')\" >> ~/mini-pupper-release
    echo CLOUD_INIT_SCRIPT=\"$(grep setup_out /boot/firmware/user-data | awk -F'"' '{print $2}')\" >> ~/mini-pupper-release
else
    echo BUILD_SCRIPT=\"$(cd ~; ls *build.sh 2>/dev/null || echo 'none')\" >> ~/mini-pupper-release
fi
echo BSP_VERSION=\"$(cd $BASEDIR; ./get-version.sh)\" >> ~/mini-pupper-release
cd $BASEDIR
TAG_COMMIT=$(git rev-list --abbrev-commit --tags --max-count=1 2>/dev/null || true)
TAG=$(git describe --abbrev=0 --tags ${TAG_COMMIT} 2>/dev/null || true)
BSP_VERSION=$(./get-version.sh)
if [ "v$BSP_VERSION" == "$TAG" ]
then
    echo IS_RELEASE=YES >> ~/mini-pupper-release
else
    echo IS_RELEASE=NO >> ~/mini-pupper-release
fi

source  ~/mini-pupper-release

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
# Ubuntu 24.04 (Noble) uses DEB822 format in /etc/apt/sources.list.d/ubuntu.sources
# Ubuntu 22.04 (Jammy) uses traditional /etc/apt/sources.list
if [ -f /etc/apt/sources.list ] && [ -s /etc/apt/sources.list ]; then
    sudo sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
fi
# mpg123 is the binary called by rc.local / battery_monitor / test.sh;
#     mpg321 installs a different binary name and must not be used here.
sudo apt install -y i2c-tools dpkg-dev curl python-is-python3 mpg123 python3-tk openssh-server screen alsa-utils libportaudio2 libsndfile1
if [ -f /etc/libao.conf ]; then
    sudo sed -i "s/pulse/alsa/" /etc/libao.conf
fi
if [ "$UBUNTU_CODENAME" == "jammy" ]; then
    sudo sed -i "s/cards.pcm.front/cards.pcm.default/" /usr/share/alsa/alsa.conf
fi

### Install LCD images
sudo rm -rf /var/lib/mini_pupper_bsp
sudo cp -r $BASEDIR/Display /var/lib/mini_pupper_bsp

### Install system components
$BASEDIR/prepare_dkms.sh
if [ "$MACHINE" == "x86_64" ]
then
    COMPONENTS=(System)
else
    COMPONENTS=(IO_Configuration FuelGauge System EEPROM PWMController)
fi
for dir in ${COMPONENTS[@]}; do
    cd $BASEDIR/$dir
    ./install.sh
done

### Install pip and Python dependencies
# Ubuntu 24.04 enforces PEP 668 (externally-managed-environment),
# so we need --break-system-packages for system-wide pip installs.
PIP_BREAK="--break-system-packages"
if [ "$UBUNTU_CODENAME" == "jammy" ]; then
    PIP_BREAK=""
fi

cd /tmp
wget https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py $PIP_BREAK
sudo pip install $PIP_BREAK setuptools lgpio
sudo pip install $PIP_BREAK sounddevice soundfile

### Install Python module
sudo apt install -y python3-dev
sudo git config --global --add safe.directory $BASEDIR
if [ "$MACHINE" == "x86_64" ]
then
    PYTHONMODLE=mock_api
else
    PYTHONMODLE=Python_Module
fi
if [ "$IS_RELEASE" == "YES" ]
then
    sudo PBR_VERSION=$(cd $BASEDIR; ./get-version.sh) pip install $PIP_BREAK $BASEDIR/$PYTHONMODLE
else
    sudo pip install $PIP_BREAK $BASEDIR/$PYTHONMODLE
fi

### Do the rest of the installation only on a physical mini pupper
if [ "$MACHINE" == "x86_64" ]
then
    exit
fi

sudo sed -i "s|BASEDIR|$BASEDIR|" /etc/rc.local
sudo sed -i "s|BASEDIR|$BASEDIR|" /usr/bin/battery_monitor

### Patch path to nvram device node
# On Ubuntu 24.04 Noble, rmem0 is already registered in the nvmem subsystem,
# so the EEPROM provider created from I2C device 3-0050 becomes 3-00501.
if [ "$UBUNTU_CODENAME" == "noble" ]; then
    sudo sed -i "s/3-00500/3-00501/" /usr/local/lib/python3.*/dist-packages/MangDang/mini_pupper/nvram.py
fi

### Make pwm sysfs and nvmem work for non-root users
### reference: https://github.com/raspberrypi/linux/issues/1983
### reference: https://github.com/bitula/mini_pupper-dev/blob/main/scripts/mini_pupper.sh
getent group gpio || sudo groupadd gpio && sudo gpasswd -a $(whoami) gpio
getent group dialout || sudo groupadd dialout && sudo gpasswd -a $(whoami) dialout
getent group spi || sudo groupadd spi && sudo gpasswd -a $(whoami) spi
sudo tee /etc/udev/rules.d/99-mini_pupper-pwm.rules << EOF > /dev/null
KERNEL=="pwmchip0", SUBSYSTEM=="pwm", RUN+="/usr/lib/udev/pwm-mini_pupper.sh"
EOF
# Two rules cover both Pi 4 (pinctrl-bcm2711) and Pi 5 (pinctrl-rp1).
sudo tee /etc/udev/rules.d/99-mini_pupper-gpio.rules << EOF > /dev/null
KERNELS=="gpiochip0", SUBSYSTEM=="gpio", ACTION=="add", ATTR{label}=="pinctrl-bcm2711", RUN+="/usr/lib/udev/gpio-mini_pupper.sh"
KERNELS=="gpiochip0", SUBSYSTEM=="gpio", ACTION=="add", ATTR{label}=="pinctrl-rp1", RUN+="/usr/lib/udev/gpio-mini_pupper.sh"
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

sudo tee /usr/lib/udev/gpio-mini_pupper.sh << 'EOF' > /dev/null
#!/bin/bash
# TODO: The sysfs GPIO ABI (/sys/class/gpio/) is formally deprecated in
# kernel 6.8 and is scheduled for removal in a future kernel release.
# This script should be migrated to use the libgpiod character device API
# (lgpio / python3-gpiod) in a future update to avoid breakage on kernel
# upgrades beyond 6.8.

# Detect GPIO base offset (kernel 6.8+ on Pi uses base 512 instead of 0)
GPIO_BASE=0
if [ -d /sys/class/gpio/gpiochip512 ]; then
    GPIO_BASE=512
fi

# Board power
PIN=$((GPIO_BASE + 21))
echo $PIN > /sys/class/gpio/export 2>/dev/null
echo out > /sys/class/gpio/gpio${PIN}/direction
chmod 666 /sys/class/gpio/gpio${PIN}/value
echo 1 > /sys/class/gpio/gpio${PIN}/value

PIN=$((GPIO_BASE + 25))
echo $PIN > /sys/class/gpio/export 2>/dev/null
echo out > /sys/class/gpio/gpio${PIN}/direction
chmod 666 /sys/class/gpio/gpio${PIN}/value
echo 1 > /sys/class/gpio/gpio${PIN}/value

# LCD power
PIN=$((GPIO_BASE + 26))
echo $PIN > /sys/class/gpio/export 2>/dev/null
echo out > /sys/class/gpio/gpio${PIN}/direction
chmod 666 /sys/class/gpio/gpio${PIN}/value
echo 1 > /sys/class/gpio/gpio${PIN}/value
EOF
sudo chmod +x /usr/lib/udev/gpio-mini_pupper.sh

sudo udevadm control --reload-rules && sudo udevadm trigger

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

