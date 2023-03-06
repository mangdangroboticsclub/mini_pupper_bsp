# Mini Pupper - ROS, OpenCV, Open-source, Pi Robot Dog

This repository is the BSP(board support package) for Mini Pupper.

Online channel: [Discord](https://discord.gg/xJdt3dHBVw), [FaceBook](https://www.facebook.com/groups/716473723088464), [YouTube](https://www.youtube.com/channel/UCqHWYGXmnoO7VWHmENje3ug/featured), [Twitter](https://twitter.com/LeggedRobot)

Mini Pupper will make robotics easier for schools, homeschool families, enthusiasts and beyond.

- ROS: support ROS SLAM&Navigation robot dog at low-cost price, endorsed by ROS.
- OpenCV: support OpenCV official OAK-D-Lite 3D camera module, endorsed by OpenCV.
- Open-source: DIY and custom what you want, won a HackadayPrize!
- Raspberry Pi: it’s super expandable, endorsed by Raspberry Pi.

## Mini Pupper Software Architecture

- mini_pupper_bsp repository: BSP(board support package) based on Ubuntu for Mini Pupper.
- mini_pupper repository: basic movement apps to control Mini Pupper by a controller or webserver or mobile app.
- mini_pupper_ros repository: ROS(Robot Operating System) packages 
	ros1:default ROS branch
	ros2:ROS 2 branch

In other words, there are 2 software versions, that is,

- Basic Ubuntu version: mini_pupper_bsp repository + mini_pupper repository.
- Beyond ROS version: mini_pupper_bsp repository + mini_pupper_ros repository.

You can enjoy Mini Pupper using [the pre-built image files](https://drive.google.com/drive/folders/12FDFbZzO61Euh8pJI9oCxN-eLVm5zjyi), or build yourself.

## About mini_pupper_bsp

[hdumcke](https://github.com/hdumcke/minipupper_base) reviewed [Mini Pupper original basic Ubuntu version repository](https://github.com/mangdangroboticsclub/QuadrupedRobot), and gave the up idea of Mini Pupper Software Architecture, and also created the [mini_pupper_bsp reference repo](https://github.com/hdumcke/minipupper_base) and released under the MIT License. Our mini_pupper_bsp repository is derived from his repository.

[Tiryoh](https://github.com/Tiryoh) is also the contributor to hdumcke's repo and Mini Pupper project. He spent much time to double confirm and co-work together to build this repo.  

Many thanks for hdumcke and Tiryoh's great support for this repository. 

Main changes compared to Mini Pupper original basic Ubuntu version repository:

- contains only the code required to get the hardware API installed
- installs on a clean Ubuntu 20.04 Server or Ubuntu 22.04 Desktop or Server for Raspberry Pi
- Python code is installed as a Python module
- no root priviledges required to drive any robot API
- make "calibrate" a system command

## Prepare installation

### Flash Ubuntu preinstalled image to the SD card. 

Choose one of the following 2 OS. Note that ROS 1 Noetic only supports Ubuntu 20.04.

* Download `ubuntu-22.04.2-preinstalled-desktop-arm64+raspi.img.xz` from the official website https://ubuntu.com/download/raspberry-pi
* Download `ubuntu-20.04.5-preinstalled-server-arm64+raspi.img.xz` from [the official website](https://cdimage.ubuntu.com/ubuntu/releases/20.04/release/) or  [our Google drive link](https://drive.google.com/drive/folders/12FDFbZzO61Euh8pJI9oCxN-eLVm5zjyi)


### Boot Raspberry Pi 

* Romote connect Pi by Ethernet or WiFi, please refer to [Find the Current IP Address of a Raspberry Pi](https://raspberrytips.com/find-current-ip-raspberry-pi/)
* Directly operate by mouse/keyboard/display

If you prefer to ubuntu 20 server version, you can follow the below steps to install the desktop.
* Put the SD card into your Raspberry Pi. 
* Connect the keyboard, mouse to the Pi, and a displayer by HDMI line. 
* Power on.
* Follow the prompts to change the password from ubuntu to mangdang, and then install desktop. Before installation, please make sure that raspberry pi is plugged into the network cable to access the Internet. 

```sh
sudo apt install ubuntu-desktop
# waiting for dozens of minutes depend on your internet spped for the install
# After installing the desktop, start the desktop. 
# You only need to reboot it one time. The system will enter the desktop system by default next time.
startx
```

## Manual installation

Manual installation is an advanced method. It is strongly recommended to use [the install script](https://github.com/mangdangroboticsclub/mini_pupper).

### Install this repository 

```sh
sudo apt update
sudo apt upgrade
sudo apt install -y git python3-pip
cd ~
git clone https://github.com/mangdangroboticsclub/mini_pupper_bsp.git
cd mini_pupper_bsp
./install.sh	
sudo reboot
```

2nd boot

```
cd ~/mini_pupper_bsp
./test.sh
```

### Calibration

There are two options how to calibrate mini pupper. You can either use a GUI or a CLI.

#### Using the GUI

```sh
calibrate  # this is a command
```

Running this command will bring up a GUI to calibrate mini pupper. For headless installation use X forwarding

#### Using the CLI

Run the command:

```sh
cli-calibrate  # this is a command
```

and follow the instructions.

Using the CLI give you fine grained control but you have to calibrate each servo every time you run cli-calibrate


## License

Copyright (c) 2020-2022 MangDang Technology Co., Limited

Most source code are licensed under MIT, but NOT include the below modules.

### GPL source code in this repository

* [EEPROM](./EEPROM)
* [FuelGauge](./FuelGauge)

### Some of the below code comes from internet, will make it clear in the futue.

* [LCD](./Python_Module/MangDang/LCD)
