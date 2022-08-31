#!/bin/bash

check_result () {

read -r -p "$1? [Y/n] " input

case $input in
      ([yY][eE][sS]|[yY]|'')
            return
            ;;
      *)
            echo "Check your installation..."
            exit 1
            ;;
esac

}

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### Test battery monitor
current_voltage=`cat /sys/class/power_supply/max1720x_battery/voltage_now`
echo "The current voltage is $current_voltage"

check_result "Did it display the current voltage"

### Test LCD driver
cd $BASEDIR/Display
python test.py
check_result "Do you see the dog on the LCD diplay"

### Test audio
mpg123 $BASEDIR/Audio/power_on.mp3
check_result "Did you hear a sound"

### Test EEPROM driver
if [ $(lsb_release -cs) == "jammy" ]; then
    hexdump /sys/bus/nvmem/devices/3-00501/nvmem
else
    hexdump /sys/bus/nvmem/devices/3-00500/nvmem
fi

check_result "Did you see a hex dump"

### Test servo
echo "Warning: the next test will move a leg. Please hold Minipupper in our hand"
check_result "Ready"

echo 1500000 > /sys/class/pwm/pwmchip0/pwm4/duty_cycle
sleep 2
echo 2000000 > /sys/class/pwm/pwmchip0/pwm4/duty_cycle

check_result "Did you see a leg moving"

### Reset servo
echo 0 > /sys/class/pwm/pwmchip0/pwm4/enable
echo 0 > /sys/class/gpio/gpio25/value
sleep 1
echo 1 > /sys/class/pwm/pwmchip0/pwm4/enable
echo 1 > /sys/class/gpio/gpio25/value

echo "Your base installation looks OK"
echo "You may now proceed to calibrate Minipupper"
