# Mini Pupper 1 BSP - ROS 2 Jazzy Migration Guide

This document describes the changes made to convert the Mini Pupper 1 BSP from ROS 2 Humble (Ubuntu 22.04) to ROS 2 Jazzy (Ubuntu 24.04) compatibility.

## Hardware Differences: Mini Pupper 1 vs Mini Pupper 2

| Feature | Mini Pupper 1 | Mini Pupper 2 |
|---------|---------------|---------------|
| Servo Protocol | Serial PWM (Lewansoul) | I2C PWM (PCA9685) |
| Display | OLED | LCD |
| Camera | RPi Camera | RPi Camera |
| Audio | Speaker | Speaker |
| Battery Gauge | BQ25895 | BQ25895 |
| Servo Count | 12 | 12 |

## Changes Made for Jazzy Compatibility

### 1. install.sh

#### Ubuntu Version Detection
```bash
UBUNTU_CODENAME=$(lsb_release -cs)
```

#### PEP 668 Support (Ubuntu 24.04+)
Ubuntu 24.04 enforces PEP 668 which prevents system-wide pip installs without explicit permission:
```bash
PIP_BREAK="--break-system-packages"
if [ "$UBUNTU_CODENAME" == "jammy" ]; then
    PIP_BREAK=""
fi
sudo pip install $PIP_BREAK <package>
```

#### Updated setuptools
Removed the pinned version `setuptools==58.2.0` and use the latest version for Python 3.12 compatibility.

#### New Dependencies
Added sounddevice and soundfile for audio playback on Ubuntu 24.04:
```bash
sudo pip install $PIP_BREAK sounddevice soundfile
```

#### DEB822 Apt Sources
Ubuntu 24.04 uses a new DEB822 format in `/etc/apt/sources.list.d/ubuntu.sources`:
```bash
if [ -f /etc/apt/sources.list ] && [ -s /etc/apt/sources.list ]; then
    sudo sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
fi
```

#### GPIO Base Offset (Kernel 6.8+)
Raspberry Pi kernel 6.8+ changed GPIO numbering from base 0 to base 512:
```bash
GPIO_BASE=0
if [ -d /sys/class/gpio/gpiochip512 ]; then
    GPIO_BASE=512
fi
PIN=$((GPIO_BASE + 21))
```

### 2. RPiCamera/install.sh

Ubuntu 24.04+ uses libcamera natively and does not require legacy camera configuration:

```bash
if [ "$UBUNTU_CODENAME" == "jammy" ]; then
    # Legacy camera config for Ubuntu 22.04
    echo "start_x=1" | sudo tee -a /boot/firmware/config.txt
else
    # Ubuntu 24.04+ uses libcamera natively
    echo "camera_auto_detect=1" | sudo tee -a /boot/firmware/config.txt
fi
```

## Installation

### Prerequisites
- Ubuntu 24.04 (Noble) on Raspberry Pi 4
- ROS 2 Jazzy installed

### Install Steps

```bash
cd ~/mini_pupper_bsp
./install.sh
sudo reboot
```

### Post-Install Verification

```bash
# Test Python module
python3 -c "from MangDang.mini_pupper.HardwareInterface import HardwareInterface; print('BSP OK')"

# Run calibration
calibrate
```

## ROS 2 Jazzy Integration

```bash
# Set robot model
export ROBOT_MODEL=mini_pupper

# Launch bringup
ros2 launch mini_pupper_bringup bringup.launch.py hardware_connected:=true
```

## Troubleshooting

### GPIO Permission Denied
```bash
sudo usermod -aG gpio $USER
sudo reboot
```

### Camera Not Detected
```bash
# Check camera is detected
libcamera-hello

# If using Ubuntu 24.04, ensure camera_auto_detect=1 in /boot/firmware/config.txt
```

### Audio Not Working
```bash
# Check audio device
aplay -l

# Set default audio device
sudo raspi-config  # Advanced Options > Audio
```

### Servo Not Responding
```bash
# Check serial port permissions
sudo usermod -aG dialout $USER

# Verify servos are connected
python3 -c "from MangDang.mini_pupper.HardwareInterface import HardwareInterface; h = HardwareInterface(); print(h.serials)"
```

## Files Modified

1. `install.sh` - Main installation script
2. `RPiCamera/install.sh` - Camera configuration script
3. `JAZZY_MIGRATION.md` - This documentation

## References

- [ROS 2 Jazzy Release Notes](https://docs.ros.org/en/jazzy/Releases/Release-Jazzy-Jalisco.html)
- [Ubuntu 24.04 Release Notes](https://discourse.ubuntu.com/t/noble-numbat-release-notes/39890)
- [PEP 668 - Externally Managed Environments](https://peps.python.org/pep-0668/)
- [Raspberry Pi Camera Documentation](https://www.raspberrypi.com/documentation/computers/camera_software.html)