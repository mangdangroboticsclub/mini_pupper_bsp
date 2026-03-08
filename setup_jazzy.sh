#!/bin/bash
#
# setup_jazzy.sh — One-shot setup for Mini Pupper 1 BSP on ROS 2 Jazzy / Ubuntu 24.04.
#
# Usage:
#   cd ~/mini_pupper_bsp
#   ./setup_jazzy.sh
#   sudo reboot
#
# The script is safe to re-run; each sub-installer is idempotent.

set -e

BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### ── Guard: Ubuntu 24.04 (Noble) only ──────────────────────────────────────
UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || true)
if [ "$UBUNTU_CODENAME" != "noble" ]; then
    echo "ERROR: This script requires Ubuntu 24.04 Noble."
    echo "       Detected codename: '${UBUNTU_CODENAME:-unknown}'"
    echo "       For Ubuntu 22.04 Jammy, use install.sh directly."
    exit 1
fi

if [ "$(uname -m)" != "aarch64" ]; then
    echo "ERROR: setup_jazzy.sh is for ARM hardware only."
    echo "       Detected architecture: '$(uname -m)'"
    echo "       This script should only be run on a Mini Pupper ARM system."
    exit 0
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   Mini Pupper 1 BSP — ROS 2 Jazzy / Ubuntu 24.04 Setup      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

### ── Helper ─────────────────────────────────────────────────────────────────
run_step() {
    local name="$1"
    local script="$2"
    echo ""
    echo "▶ Step: ${name}"
    echo "  Script: ${script}"
    if [ ! -f "$script" ]; then
        echo "  WARNING: ${script} not found — skipping."
        return 0
    fi
    bash "$script"
    echo "  ✓ ${name} complete."
}

### ── Installation steps ─────────────────────────────────────────────────────

# Main BSP install: Python modules, DKMS drivers, pip deps, udev rules, audio.
# This also runs IO_Configuration, FuelGauge, System, EEPROM, and PWMController
# internally for ARM hardware.
run_step "Main BSP install" "$BASEDIR/install.sh"

# RPiCamera: configures libcamera (Noble) or legacy stack (Jammy).
run_step "RPiCamera" "$BASEDIR/RPiCamera/install.sh"

### ── Done ───────────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   Installation complete!  Reboot required.                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Post-reboot verification checklist:"
echo ""
echo "  1. Reboot now:"
echo "       sudo reboot"
echo ""
echo "  2. Verify BSP Python module loads:"
echo "       python3 -c \"from MangDang.mini_pupper.HardwareInterface import HardwareInterface; print('BSP OK')\""
echo ""
echo "  3. Verify I2C buses (EEPROM on bus 3, fuel gauge on bus 4):"
echo "       i2cdetect -y 3"
echo "       i2cdetect -y 4"
echo ""
echo "  4. Verify PWM sysfs nodes:"
echo "       ls /sys/class/pwm/pwmchip0/"
echo ""
echo "  5. Verify camera (libcamera):"
echo "       libcamera-hello --timeout 2000"
echo ""
echo "  6. Verify audio devices:"
echo "       aplay -l"
echo ""
echo "  7. Verify battery gauge:"
echo "       cat /sys/class/power_supply/max1720x_battery/voltage_now"
echo ""
echo "  8. Run servo calibration:"
echo "       calibrate"
echo ""
echo "  9. Check ROS 2 Jazzy bringup (after sourcing your workspace):"
echo "       export ROBOT_MODEL=mini_pupper"
echo "       ros2 launch mini_pupper_bringup bringup.launch.py hardware_connected:=true"
echo ""
