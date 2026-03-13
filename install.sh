#!/bin/bash

set -e
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

# Fix package dependency issues for Ubuntu 24.04 (Noble)
# Some systems may have security-updated versions that conflict with repository versions
if [ "$UBUNTU_CODENAME" == "noble" ]; then
    echo "Fixing potential package version conflicts for Ubuntu 24.04..."
    sudo apt clean
    sudo apt --fix-broken install -y || true
    
    # Check if libbz2-1.0 and zlib1g need downgrade to match repository versions
    # This prevents "unmet dependencies" errors when installing build-essential
    LIBBZ2_INSTALLED=$(dpkg -l libbz2-1.0 2>/dev/null | grep "^ii" | awk '{print $3}' || echo "")
    ZLIB1G_INSTALLED=$(dpkg -l zlib1g 2>/dev/null | grep "^ii" | awk '{print $3}' || echo "")
    
    if [ -n "$LIBBZ2_INSTALLED" ] && [ "$LIBBZ2_INSTALLED" != "1.0.8-5.1" ]; then
        echo "Downgrading libbz2-1.0 to repository version..."
        sudo apt install --allow-downgrades -y libbz2-1.0=1.0.8-5.1 || true
    fi
    
    if [ -n "$ZLIB1G_INSTALLED" ] && [ "$ZLIB1G_INSTALLED" != "1:1.3.dfsg-3.1ubuntu2" ]; then
        echo "Downgrading zlib1g to repository version..."
        sudo apt install --allow-downgrades -y zlib1g=1:1.3.dfsg-3.1ubuntu2 || true
    fi
    
    # Install bzip2 and zlib1g-dev with specific versions to avoid conflicts
    sudo apt install -y bzip2=1.0.8-5.1 zlib1g-dev=1:1.3.dfsg-3.1ubuntu2 || \
    sudo apt install -y bzip2 zlib1g-dev
fi

# mpg123 is the binary called by rc.local / test.sh;
# mpg321 installs a different binary name and must not be used here.
# Install build tools and Python dependencies first (needed for DKMS and pip installs)
sudo apt install -y build-essential python3-pip python3-dev
sudo apt install -y i2c-tools curl python-is-python3 mpg123 python3-tk openssh-server screen alsa-utils libportaudio2 libsndfile1
if [ -f /etc/libao.conf ]; then
    sudo sed -i "s/pulse/alsa/" /etc/libao.conf
fi
if [ "$UBUNTU_CODENAME" == "jammy" ]; then
    sudo sed -i "s/cards.pcm.front/cards.pcm.default/" /usr/share/alsa/alsa.conf
fi

### Install LCD images
sudo rm -rf /var/lib/mini_pupper_bsp
sudo cp -r $BASEDIR/Display /var/lib/mini_pupper_bsp

### Install kernel headers for DKMS module compilation
KERNEL_VERSION=$(uname -r)
sudo apt install -y linux-headers-${KERNEL_VERSION} || echo "Warning: Could not install exact kernel headers, trying generic..."
if ! dpkg -l | grep -q "linux-headers-${KERNEL_VERSION}"; then
    # Try to install generic raspi headers if exact version not available
    sudo apt install -y linux-headers-raspi || true
fi

### Install system components
$BASEDIR/prepare_dkms.sh
if [ "$MACHINE" == "x86_64" ]
then
    COMPONENTS=(System)
else
    COMPONENTS=(IO_Configuration System EEPROM PWMController)
fi
for dir in ${COMPONENTS[@]}; do
    cd $BASEDIR/$dir
    ./install.sh
done

### Install pip and Python dependencies
# Ubuntu 24.04 enforces PEP 668 (externally-managed-environment),
# so we need --break-system-packages for system-wide pip installs.
PIP_BREAK=""
if [ "$UBUNTU_CODENAME" == "noble" ]; then
    PIP_BREAK="--break-system-packages"
fi

cd /tmp
# Skip pip upgrade to avoid conflicts with system-managed pip
# wget https://bootstrap.pypa.io/get-pip.py
# sudo python get-pip.py $PIP_BREAK || true
sudo pip3 install $PIP_BREAK setuptools lgpio

### Install Python module
# python3-dev already installed above
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
    sudo pip3 install $PIP_BREAK $BASEDIR/$PYTHONMODLE
fi

### Do the rest of the installation only on a physical mini pupper
if [ "$MACHINE" == "x86_64" ]
then
    exit
fi

sudo sed -i "s|BASEDIR|$BASEDIR|" /etc/rc.local

### Patch path to nvram device node
# On Ubuntu 24.04 Noble, rmem0 and rmem1 are already registered in the nvmem subsystem,
# so the EEPROM provider created from I2C device 3-0050 becomes 3-00502.
if [ "$UBUNTU_CODENAME" == "noble" ]; then
    sudo sed -i "s/3-00500/3-00502/" /usr/local/lib/python3.*/dist-packages/MangDang/mini_pupper/nvram.py
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
# Pi 4 udev rule (pinctrl-bcm2711)
# Support both old kernel (gpiochip0) and kernel 6.8+ (gpiochip512)
sudo tee /etc/udev/rules.d/99-mini_pupper-gpio.rules << EOF > /dev/null
SUBSYSTEM=="gpio", ACTION=="add", ATTR{label}=="pinctrl-bcm2711", RUN+="/usr/lib/udev/gpio-mini_pupper.sh"
KERNEL=="gpiomem", OWNER="root", GROUP="gpio", MODE="0660"
EOF
sudo tee /etc/udev/rules.d/99-mini_pupper-nvmem.rules << EOF > /dev/null
KERNEL=="3-00500", SUBSYSTEM=="nvmem", RUN+="/bin/chmod 666 /sys/bus/nvmem/devices/3-00500/nvmem"
KERNEL=="3-00501", SUBSYSTEM=="nvmem", RUN+="/bin/chmod 666 /sys/bus/nvmem/devices/3-00501/nvmem"
KERNEL=="3-00502", SUBSYSTEM=="nvmem", RUN+="/bin/chmod 666 /sys/bus/nvmem/devices/3-00502/nvmem"
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
for f in test.sh System/rc.local; do
    if ! grep -q "mpg123 -a" $BASEDIR/$f; then
        sed -i -e "s/mpg123/mpg123 -a ${AUDIO_DEVICE:-hw:0,1}/g" $BASEDIR/$f
    fi
done
if ! grep -q "mpg123 -a" /etc/rc.local; then
    sudo sed -i -e "s/mpg123/mpg123 -a ${AUDIO_DEVICE:-hw:0,1}/g" /etc/rc.local
fi

