This Project is the BSP(board support package) for MiniPupper.

-------------Flash Ubuntu baseline image------------------
Download ubuntu-22.04.1-preinstalled-desktop-arm64+raspi.img from the below link,
https://ubuntu.com/download/raspberry-pi

Flash the image to the SD card.
user name: ubuntu
password: mangdang

-------------Install system packages------------------
	$sudo apt update
	$sudo apt install openssh-server net-tools git make  python3-pip i2c-tools
	$pip3 install numpy RPi.GPIO spidev

-------------Install Mini Pupper BSP packages------------------

	$cd ~
	$mkdir QuadrupedRobot
	$git cone https://github.com/mangdangroboticsclub/minipupper-bsp.git
	$cd QuadrupedRobot/minipupper-bsp
	$sudo sh install.sh
	$reboot


