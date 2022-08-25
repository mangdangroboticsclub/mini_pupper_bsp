# Mini Pupper - ROS, OpenCV, Open-source, Pi Robot Dog

This repository is the BSP(board support package) for MiniPupper.

Online channel: [Discord](https://discord.gg/xJdt3dHBVw), [FaceBook](https://www.facebook.com/groups/716473723088464), [Youtube](https://www.youtube.com/channel/UCqHWYGXmnoO7VWHmENje3ug/featured), [Twitter](https://twitter.com/LeggedRobot)

Mini Pupper will make robotics easier for schools, homeschool families, enthusiasts and beyond.

- ROS: support ROS SLAM&Navigation robot dog at low-cost price, endorsed by ROS.
- OpenCV: support OpenCV official OAK-D-Lite 3D camera module, endorsed by OpenCV.
- Open-source: DIY and custom what you want, won a HackadayPrize!
- Raspberry Pi: it’s super expandable, endorsed by Raspberry Pi.

## Mini Pupper Software Architecture

- minipupper-bsp repository: BSP(board support package) based on Ubuntu for MiniPupper.
- minipupper repository: basic movement apps to control Mini Pupper by a controller or webserver or mobile app.
- minipupper-ros repository: ROS(Robot Operating System) packages 
	minipupper-ros1:default ROS branch
	minipupper-ros2:ROS2 branch

In other words, there are 2 software versions, that is,

- Basic Ubuntu version: minipupper-bsp repository + minipupper repository.
- Beyond ROS version: minipupper-bsp repository + minipupper-ros repository.

You can enjoy Mini Pupper using [the pre-built image files](https://drive.google.com/drive/folders/12FDFbZzO61Euh8pJI9oCxN-eLVm5zjyi), or build yourself.

## About minipupper-bsp

[hdumcke](https://github.com/hdumcke/minipupper_base) reviewed [Mini Pupper original basic Ubuntu version repository](https://github.com/mangdangroboticsclub/QuadrupedRobot), and gave the up idea of Mini Pupper Software Architecture, and also created a [minipupper-bsp reference repo](https://github.com/hdumcke/minipupper_base), [Tiryoh](https://github.com/Tiryoh) is also the contributor to hdumcke's repo and Mini Pupper project.

Tiryoh spent much time to double confirm and co-work together to build this repo.  

Many thanks for hdumcke and Tiryoh's great support for this repository. 

Main changes compared to Mini Pupper original basic Ubuntu version repository:

- contains only the code required to get the hardware API installed
- installs on a clean Unutu 22.04 Desktop(Raspberry Pi)
- Python code is installed as a Python module
- No root priviledges required to drive any robot API
- calibrate is a system command

## Installation

- Flash Ubuntu 22.04 64bit to SD card. 

	Download ubuntu-22.04.1-preinstalled-desktop-arm64+raspi.img from the link, https://ubuntu.com/download/raspberry-pi .
	
- Boot Raspberry Pi 

	Romote connect Pi by Ethernet or WiFi, please refer to [Find the Current IP Address of a Raspberry Pi](https://raspberrytips.com/find-current-ip-raspberry-pi/)
	
	Directly operate by mouse/keyboard/display
	
- Install this repository 

	$git clone https://github.com/hdumcke/minipupper_base.git
	
	$./minipupper_base/install.sh
	
	$reboot	
	
	$./minipupper_base/update_kernel_modules.sh
	
	$reboot	
	
	$./minipupper_base/test.sh


## Calibration

	# this is a command
	$calibrate 


## Licensing Issue
Most source code are licensed under MIT, but NOT include the below modules.

### GPL source code in this repository
[EEPROM](EEPROM)

[FuelGauge](FuelGauge)

### Some of the below code comes from internet, will make it clear in the futue.
[LCD](Python_Modules/MangDang/LCD)