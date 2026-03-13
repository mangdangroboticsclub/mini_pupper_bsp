#!/usr/bin/env python3
"""
Mini Pupper BSP — Overkill cleanup script
Strips unnecessary comments, fixes dead README link, removes unused packages.
Run from inside ~/jazzy:
    python3 cleanup_overkill.py
"""

import os
import sys
import re

JAZZY = os.path.dirname(os.path.abspath(__file__))
# If running from elsewhere, allow path argument
if len(sys.argv) > 1:
    JAZZY = sys.argv[1]

changes = []

def edit(filepath, old, new, description):
    full = os.path.join(JAZZY, filepath)
    if not os.path.exists(full):
        print(f"  ⚠️  SKIP  {filepath} — file not found")
        return
    with open(full, 'r') as f:
        content = f.read()
    if old not in content:
        print(f"  ⚠️  SKIP  {filepath} — pattern not found: {repr(old[:60])}")
        return
    with open(full, 'w') as f:
        f.write(content.replace(old, new, 1))
    changes.append(f"{filepath}: {description}")
    print(f"  ✅  {filepath}: {description}")


print("\n══════════════════════════════════════════════════")
print("  Mini Pupper BSP — Overkill Comment Cleanup")
print(f"  Target: {JAZZY}")
print("══════════════════════════════════════════════════\n")

# ── install.sh ────────────────────────────────────────────────────────────────

edit("install.sh",
    "sudo apt update\n"
    "# NOTE: Run 'sudo apt update && sudo apt upgrade' manually before running\n"
    "# this script to ensure system packages are up to date. Performing a full\n"
    "# upgrade here risks changing the running kernel mid-install, which would\n"
    "# invalidate DKMS modules built in the steps below.\n",
    "sudo apt update\n",
    "Remove apt upgrade NOTE comment")

edit("install.sh",
    "# Ubuntu 24.04 (Noble) uses DEB822 format in /etc/apt/sources.list.d/ubuntu.sources\n"
    "# Ubuntu 22.04 (Jammy) uses traditional /etc/apt/sources.list\n"
    "if [ -f /etc/apt/sources.list ]",
    "if [ -f /etc/apt/sources.list ]",
    "Remove DEB822 format comment")

edit("install.sh",
    "# mpg123 is the binary called by rc.local / battery_monitor / test.sh;\n"
    "#     mpg321 installs a different binary name and must not be used here.\n"
    "sudo apt install",
    "sudo apt install",
    "Remove mpg123 vs mpg321 comment")

edit("install.sh",
    " screen alsa-utils libportaudio2 libsndfile1",
    " alsa-utils",
    "Remove screen, libportaudio2, libsndfile1 from apt install")

edit("install.sh",
    "### Install pip and Python dependencies\n"
    "# Ubuntu 24.04 enforces PEP 668 (externally-managed-environment),\n"
    "# so we need --break-system-packages for system-wide pip installs.\n",
    "### Install pip and Python dependencies\n",
    "Remove PEP 668 comment")

edit("install.sh",
    "### Patch path to nvram device node\n"
    "# On Ubuntu 24.04 Noble, rmem0 is already registered in the nvmem subsystem,\n"
    "# so the EEPROM provider created from I2C device 3-0050 becomes 3-00501.\n",
    "### Patch path to nvram device node\n",
    "Remove nvmem rmem0 explanation comment")

edit("install.sh",
    "EOF\n"
    "# Pi 4 udev rule (pinctrl-bcm2711)\n"
    "sudo tee /etc/udev/rules.d/99-mini_pupper-gpio.rules",
    "EOF\n"
    "sudo tee /etc/udev/rules.d/99-mini_pupper-gpio.rules",
    "Remove Pi 4 udev rule label comment")

edit("install.sh",
    "#!/bin/bash\n"
    "# TODO: The sysfs GPIO ABI (/sys/class/gpio/) is formally deprecated in\n"
    "# kernel 6.8 and is scheduled for removal in a future kernel release.\n"
    "# This script should be migrated to use the libgpiod character device API\n"
    "# (lgpio / python3-gpiod) in a future update to avoid breakage on kernel\n"
    "# upgrades beyond 6.8.\n"
    "\n"
    "# Detect GPIO base offset (kernel 6.8+ on Pi uses base 512 instead of 0)\n",
    "#!/bin/bash\n"
    "# Detect GPIO base offset (kernel 6.8+: base 512, older: base 0)\n",
    "Remove TODO block, condense GPIO base comment in udev heredoc")

# ── FuelGauge/battery_monitor ─────────────────────────────────────────────────

edit("FuelGauge/battery_monitor",
    "\t\t# Kernel 6.8+ (Ubuntu 24.04) uses GPIO base offset 512; detect dynamically\n"
    "\t\tGPIO_BASE=0",
    "\t\tGPIO_BASE=0",
    "Remove GPIO base offset comment")

# ── test.sh ───────────────────────────────────────────────────────────────────

edit("test.sh",
    "### Reset servo\n"
    "# Kernel 6.8+ on Ubuntu 24.04 uses GPIO base offset 512; detect dynamically.\n"
    "GPIO_BASE=0",
    "### Reset servo\n"
    "GPIO_BASE=0",
    "Remove GPIO base offset comment")

# ── EEPROM/ubuntu_20.04/at24.c ───────────────────────────────────────────────

edit("EEPROM/ubuntu_20.04/at24.c",
    "// SPDX-License-Identifier: GPL-2.0+\n"
    "/* Retained for reference only; no current install script uses this 20.04 driver. */\n",
    "// SPDX-License-Identifier: GPL-2.0+\n",
    "Remove 'retained for reference' comment")

# ── prepare_dkms.sh ───────────────────────────────────────────────────────────

edit("prepare_dkms.sh",
    "# Remove orphan DKMS entries not part of this BSP\n"
    "sudo dkms remove",
    "sudo dkms remove",
    "Remove orphan DKMS comment")

edit("prepare_dkms.sh",
    "# Use inherited UBUNTU_CODENAME if set, otherwise detect\n"
    "UBUNTU_CODENAME=",
    "UBUNTU_CODENAME=",
    "Remove UBUNTU_CODENAME inheritance comment")

# ── Python_Module/MangDang/Adafruit_GPIO/GPIO.py ─────────────────────────────

edit("Python_Module/MangDang/Adafruit_GPIO/GPIO.py",
    "        # RPi.GPIO is not supported on Ubuntu 24.04 Noble / kernel 6.8.\n"
    "        # Use lgpio directly via the ST7789 driver instead of this adapter path.\n"
    "        raise NotImplementedError",
    "        raise NotImplementedError",
    "Remove RPi.GPIO explanation comments (error message is self-explanatory)")

# ── Python_Module/MangDang/LCD/ST7789.py ─────────────────────────────────────

edit("Python_Module/MangDang/LCD/ST7789.py",
    "        # Open gpiochip0 — the BCM GPIO controller on Pi 4/5.\n"
    "        # lgpio uses BCM pin numbers directly via the character device;\n"
    "        # it is unaffected by the sysfs base-offset change in kernel 6.8+.\n"
    "        self._h = lgpio.gpiochip_open(0)",
    "        self._h = lgpio.gpiochip_open(0)",
    "Remove gpiochip_open explanation comment")

# ── Python_Module/MangDang/mini_pupper/display.py ────────────────────────────

edit("Python_Module/MangDang/mini_pupper/display.py",
    "        # resize() returns a new Image; assign back to avoid displaying unscaled image\n"
    "        image = image.resize((320, 240))\n"
    "        self.disp.display(image)",
    "        image = image.resize((320, 240))\n"
    "        self.disp.display(image)",
    "Remove resize() comment in show_image")

edit("Python_Module/MangDang/mini_pupper/display.py",
    "        # Assign the resized image before drawing text.\n"
    "        image = image.resize((320, 240))\n"
    "        # Use psutil instead of the unmaintained netifaces package.\n"
    "        ip = 'no IPv4 address found'",
    "        image = image.resize((320, 240))\n"
    "        ip = 'no IPv4 address found'",
    "Remove resize and psutil comments in show_ip")

# ── Python_Module/MangDang/mini_pupper/nvram.py ──────────────────────────────

edit("Python_Module/MangDang/mini_pupper/nvram.py",
    "# Hardware EEPROM path (AT24C08 on I2C bus 3).\n"
    "# NOTE: Requires the at24 kernel module to be loaded and the DT overlay to\n"
    "# instantiate the device. On Ubuntu 24.04 / kernel 6.8 this may not happen\n"
    "# automatically until the DKMS at24 module is rebuilt for kernel 6.8.\n"
    "#\n"
    "# The device path varies by kernel version:\n"
    "#   - Ubuntu 22.04 (Jammy): typically 3-00500\n"
    "#   - Ubuntu 24.04 (Noble): typically 3-00501 (rmem0 claims 3-00500)\n",
    "# EEPROM nvmem path: 3-00500 (Jammy) or 3-00501 (Noble)\n",
    "Trim 9-line nvmem comment to 1 line")

# ── RPiCamera/install.sh ──────────────────────────────────────────────────────

edit("RPiCamera/install.sh",
    "# Version: 1.2 (Jazzy compatible)\n"
    "# Date: 2026-03-01",
    "# Version: 1.1\n"
    "# Date: 2023-04-10",
    "Revert version bump and date (cosmetic, unnecessary change)")

edit("RPiCamera/install.sh",
    "# Update the package index.\n"
    "# NOTE: Run 'sudo apt update && sudo apt upgrade' manually before running\n"
    "# this script to ensure system packages are up to date. Performing a full\n"
    "# upgrade here risks changing the running kernel mid-install, which would\n"
    "# invalidate DKMS modules built in earlier setup steps.\n"
    "sudo apt update",
    "sudo apt update",
    "Remove apt upgrade NOTE comment")

edit("RPiCamera/install.sh",
    "# Ubuntu 22.04 (Jammy) uses legacy camera configuration\n"
    "# Ubuntu 24.04+ (Noble+) uses libcamera natively\n"
    "if [ \"$UBUNTU_CODENAME\" == \"jammy\" ]",
    "if [ \"$UBUNTU_CODENAME\" == \"jammy\" ]",
    "Remove camera stack split comment")

# ── README.md — fix dead link ─────────────────────────────────────────────────

edit("README.md",
    "* See [JAZZY_MIGRATION.md](./JAZZY_MIGRATION.md) for Noble-specific details and post-install verification steps\n",
    "",
    "Remove dead link to deleted JAZZY_MIGRATION.md")

# ── Summary ───────────────────────────────────────────────────────────────────

print(f"\n══════════════════════════════════════════════════")
print(f"  {len(changes)} changes made.")
print(f"══════════════════════════════════════════════════")
print("\nNext steps:")
print("  git rm verify_noble.sh")
print("  git add -A")
print('  git commit -m "Strip overkill comments, remove unused packages, fix dead README link"')
print("  git push origin main\n")
