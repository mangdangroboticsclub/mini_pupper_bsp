#!/bin/bash
#
# This script configures a Raspberry Pi for use with a camera module.
# Version: 1.1
# Date: 2023-04-10

# Exit the script immediately if a command exits with a non-zero status
# set -x
set -e

# Get the directory where this script is located
BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Detect Ubuntu version
UBUNTU_CODENAME=$(lsb_release -cs)
echo "Detected Ubuntu codename: $UBUNTU_CODENAME"

sudo apt update

# Install v4l2, a video capture utility
sudo apt install -y v4l-utils

if [ "$UBUNTU_CODENAME" == "jammy" ]; then
    echo "Configuring legacy camera support for Ubuntu 22.04..."
    # Edit the /boot/firmware/config.txt file to enable camera support
    sudo sed -i 's/^camera_auto_detect=1/# camera_auto_detect=1/g' /boot/firmware/config.txt
    echo "gpu_mem=128" | sudo tee -a /boot/firmware/config.txt
    echo "start_x=1" | sudo tee -a /boot/firmware/config.txt
    
    # Compile the dt-blob file to support the camera
    cd $BASEDIR/dts
    sudo dtc -I dts -O dtb -o /boot/firmware/dt-blob.bin dt-blob-cam1.dts
else
    echo "Ubuntu 24.04+ uses libcamera natively - skipping legacy camera config"
    # Install libcamera userspace tools and Python bindings.
    # Ubuntu 24.04 server/minimal images do not ship these by default.
    sudo apt install -y libcamera-apps libcamera-tools python3-libcamera
    # Ensure camera_auto_detect is enabled in the boot config
    if grep -q "^# camera_auto_detect=1" /boot/firmware/config.txt; then
        sudo sed -i 's/^# camera_auto_detect=1/camera_auto_detect=1/g' /boot/firmware/config.txt
    elif ! grep -q "camera_auto_detect=1" /boot/firmware/config.txt; then
        echo "camera_auto_detect=1" | sudo tee -a /boot/firmware/config.txt
    fi
fi

# Add the user to the video group to grant access to video devices
sudo usermod -aG video $USER

# Print successful information
echo "Camera settings successful, changes will be applied after the next reboot."
