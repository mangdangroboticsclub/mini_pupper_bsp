# Mini Pupper 1 BSP — Jazzy Migration Fix Log

All issues identified in the Ubuntu 24.04 / ROS 2 Jazzy migration review
have been addressed. Changes are grouped by severity.

---

## Critical Fixes

### C1 — `IO_Configuration/install.sh` + `IO_Configuration/ubuntu_24.04/config.txt` (new)
**Problem:** The `else` branch (Noble) was copying `ubuntu_20.04/syscfg.txt` to
`/boot/firmware/` as `syscfg.txt`, leaving no valid `config.txt` with the
required hardware device-tree overlays (`i2c-pwm-pca9685a`, `i2c3`, `i2c4`,
`spi`, `uart`, `audremap`, etc.). None of the mini pupper hardware would
initialise at boot.  
**Fix:** Created `IO_Configuration/ubuntu_24.04/config.txt` (identical hardware
overlays to the 22.04 version; `camera_auto_detect=1` already present). Updated
`install.sh` so the `else` branch copies this file to `/boot/firmware/config.txt`.

---

### C2 — `prepare_dkms.sh`
**Problem:** Noble fell through to `ubuntu_20.04/at24.c` (a kernel 5.4 driver),
which fails to compile against kernel 6.8.  
**Fix:** Changed the `else` branch to use `ubuntu_22.04/at24.c` as the best
available fallback. Added a `TODO` comment noting that a kernel-6.8-validated
`ubuntu_24.04/at24.c` is needed for production use.

---

### C3 — `FuelGauge/battery_monitor`
**Problem:** Writes to `/sys/class/gpio/gpio25/value` and `gpio21/value` are
hardcoded without the base-512 offset introduced in kernel 6.8+. The sysfs
nodes do not exist, so low-battery power cuts silently fail.  
**Fix:** Added runtime GPIO base detection (`GPIO_BASE=512` when `gpiochip512`
exists) and rewrote the writes as `gpio$((GPIO_BASE + 25))` and
`gpio$((GPIO_BASE + 21))`.

---

### C4 — `Python_Module/MangDang/LCD/ST7789.py`
**Problem:** `import RPi.GPIO as GPIO` is incompatible with kernel 6.8+ and
Python 3.12 (unmaintained library, changed `/dev/gpiomem` ABI). Every import of
the LCD driver would crash.  
**Fix:** Replaced `RPi.GPIO` entirely with `lgpio`. Opens `gpiochip_open(0)` at
`__init__`, stores the handle as `self._h`, and uses `gpio_claim_output` /
`gpio_write` throughout. Added `__del__` to close the chip handle cleanly.
`lgpio` uses BCM pin numbers via the character device and is unaffected by the
sysfs base-offset change.

---

### C5 — `Python_Module/MangDang/Adafruit_GPIO/Platform.py`
**Problem:** `pi_version()` returned `None` for `BCM2711` (Pi 4) and `BCM2712`
(Pi 5), causing `platform_detect()` to return `UNKNOWN` and
`get_platform_gpio()` to raise `RuntimeError`. Calibration and any GPIO path
through the Adafruit wrapper would crash on a Pi 4.  
**Fix:** Added `elif match.group(1) in ('BCM2711', 'BCM2712'): return 4`.

---

### C6 — `setup_jazzy.sh` (new file)
**Problem:** The file was referenced in the migration guide but missing from the
repository.  
**Fix:** Created `setup_jazzy.sh` at the repo root. It:
- Guards against running on non-Noble systems (exits with a clear error).
- Runs each install step in sequence with pass/fail reporting.
- Prints a numbered post-reboot verification checklist covering I2C, PWM,
  camera, audio, battery gauge, calibration, and ROS 2 bringup.

---

## Warning Fixes

### W1 — `install.sh`
**Problem:** `mpg321` was listed in the `apt install` line but the binary it
installs is `mpg321`, not `mpg123`. All audio playback calls in `rc.local`,
`battery_monitor`, and `test.sh` use `mpg123`, which would be missing.  
**Fix:** Changed `mpg321` to `mpg123` in the apt install invocation.

---

### W2 — `System/install.sh`, `FuelGauge/install.sh`
**Problem:** Service files were being copied to `/lib/systemd/system/`, which
is a deprecated compatibility symlink on Ubuntu 24.04.  
**Fix:** Changed both copy destinations to `/usr/lib/systemd/system/`.

---

### W3 — `System/rc.local`
**Problem:** The `check-reconfigure.sh` path was hardcoded as
`/home/ubuntu/mini_pupper_bsp/...`, breaking for any username other than
`ubuntu`.  
**Fix:** Replaced the hardcoded path with `BASEDIR/System/check-reconfigure.sh`.
The existing `sed -i "s|BASEDIR|$BASEDIR|" /etc/rc.local` in `install.sh`
already substitutes this placeholder correctly.

---

### W4 — `install.sh` (udev GPIO rule)
**Problem:** The udev `ATTR{label}=="pinctrl-bcm2711"` rule only matches Pi 4.
On Pi 5, the label is `pinctrl-rp1`, so `gpio-mini_pupper.sh` would never fire.  
**Fix:** Added a second udev rule line for `ATTR{label}=="pinctrl-rp1"` so both
Pi 4 and Pi 5 trigger the GPIO setup script. (udev `==` does not support OR
patterns; two rules are the correct approach.)

---

### W5 — `RPiCamera/install.sh`
**Problem:** The Noble branch relied on libcamera being "available out of the
box", but Ubuntu 24.04 server/minimal images do not ship `libcamera-apps`,
`libcamera-tools`, or `python3-libcamera`. Camera would not function after
install.  
**Fix:** Added `sudo apt install -y libcamera-apps libcamera-tools python3-libcamera`
to the Noble branch.

---

### W6 — `FuelGauge/battery_monitor.service`
**Problem:** `WantedBy=sysinit.target` starts the service before I2C buses and
hardware drivers are ready. The MAX1720x battery gauge may not be enumerated at
that point.  
**Fix:** Changed `WantedBy` to `multi-user.target` and added `After=network.target`.

---

### W7 — `Python_Module/MangDang/mini_pupper/display.py` + `requirements.txt`
**Problem:** `netifaces` is unmaintained (broken on Python 3.12) and was absent
from `requirements.txt`. The IP display would crash at import or runtime.  
**Fix:** Replaced `import netifaces as ni` with `import psutil` and `import socket`.
Rewrote `show_ip()` to iterate `psutil.net_if_addrs()` with `socket.AF_INET`
family filtering. Added `psutil` to `requirements.txt`; replaced `RPi.GPIO` with
`lgpio` in `requirements.txt`.

---

### W8 — `install.sh` (nvram path patch)
**Problem:** The `3-00500 → 3-00501` nvmem path patch was only applied on Jammy,
leaving Noble with an unverified (and potentially wrong) hardcoded path.  
**Fix:** Extended the conditional to `if [ "$UBUNTU_CODENAME" == "jammy" ] || [ "$UBUNTU_CODENAME" == "noble" ]`. Added a `TODO` comment to verify the correct nvmem path on Noble hardware before production use.

---

### W9 — `install.sh`
**Problem:** `sudo apt -y upgrade` at the top of the script could silently
upgrade the running kernel, invalidating DKMS modules built in subsequent steps.  
**Fix:** Removed the upgrade invocation and replaced it with a comment advising
users to run `apt upgrade` manually before starting the install script.

---

## Suggestion Fixes

### S1 — `Python_Module/MangDang/mini_pupper/HardwareInterface.py`
**Problem:** `open(file_node, "w")` in `send_servo_commands` and
`send_servo_command` was not paired with a `close()`. At 12 servos × control
frequency, file descriptors leaked rapidly.  
**Fix:** Wrapped both `open()` + `write()` pairs in `with open(...) as f:`.

---

### S2 — `Python_Module/MangDang/mini_pupper/display.py`
**Problem:** `image.resize((320, 240))` in `show_image()` and `show_ip()` was
called but its return value discarded. The display always received the original
unscaled image.  
**Fix:** Changed to `image = image.resize((320, 240))` in both methods.

---

### S3 — `Python_Module/setup.cfg`
**Problem:** `[files] packages = MangDang` (pbr legacy syntax) only listed the
top-level namespace package. Sub-packages (`MangDang.mini_pupper`,
`MangDang.Adafruit_GPIO`, `MangDang.LCD`) might be omitted from the installed
wheel under newer setuptools.  
**Fix:** Removed the `[files]` section. Added `packages = find:` under `[options]`
so setuptools auto-discovers all sub-packages.

---

### S4 — `install.sh` (gpio-mini_pupper.sh heredoc)
**Problem:** The `gpio-mini_pupper.sh` udev helper uses the sysfs GPIO ABI
(`/sys/class/gpio/`) which is formally deprecated in kernel 6.8 and may be
removed in a future kernel.  
**Fix:** Added a prominent `TODO` comment at the top of the heredoc noting the
deprecation and the required migration path to `libgpiod` / `python3-gpiod`.

---

### S5 — `System/rc-local.service`
**Problem:** `After=network.target` was commented out, so `rc.local` could run
before DHCP completed. `display.py::show_ip()` would always show "no IPv4
address found".  
**Fix:** Uncommented `After=network.target` and added `Wants=network-online.target`
+ `After=network-online.target` to ensure the network is fully up before the
startup sequence runs.

---

## File Index

| File | Change |
|------|--------|
| `IO_Configuration/ubuntu_24.04/config.txt` | **NEW** — Noble boot config with all required DT overlays |
| `IO_Configuration/install.sh` | C1 — use ubuntu_24.04/config.txt for Noble |
| `prepare_dkms.sh` | C2 — Noble uses ubuntu_22.04 at24 source; TODO added |
| `FuelGauge/battery_monitor` | C3 — dynamic GPIO_BASE detection for kernel 6.8+ |
| `Python_Module/MangDang/LCD/ST7789.py` | C4 — RPi.GPIO → lgpio; __del__ cleanup |
| `Python_Module/MangDang/Adafruit_GPIO/Platform.py` | C5 — BCM2711/BCM2712 Pi4/Pi5 detection |
| `setup_jazzy.sh` | **NEW** — C6 — automated Jazzy setup script |
| `install.sh` | W1/W4/W8/W9/S4 — mpg123, Pi5 udev, Noble nvram, no unsafe upgrade, GPIO TODO |
| `System/install.sh` | W2 — /usr/lib/systemd/system/ |
| `FuelGauge/install.sh` | W2 — /usr/lib/systemd/system/ |
| `System/rc.local` | W3 — BASEDIR placeholder replaces hardcoded /home/ubuntu |
| `RPiCamera/install.sh` | W5 — libcamera-apps/tools/python3-libcamera for Noble |
| `FuelGauge/battery_monitor.service` | W6 — multi-user.target; After=network.target |
| `Python_Module/MangDang/mini_pupper/display.py` | W7/S2 — psutil replaces netifaces; resize() fixed |
| `Python_Module/requirements.txt` | W7 — lgpio replaces RPi.GPIO; psutil added |
| `Python_Module/MangDang/mini_pupper/HardwareInterface.py` | S1 — with-statement file handles |
| `Python_Module/setup.cfg` | S3 — packages = find: |
| `System/rc-local.service` | S5 — network-online.target ordering |
