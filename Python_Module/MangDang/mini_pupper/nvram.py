import os
import pickle

# Hardware EEPROM path (AT24C08 on I2C bus 3).
# NOTE: Requires the at24 kernel module to be loaded and the DT overlay to
# instantiate the device.  On Ubuntu 24.04 / kernel 6.8 this may not happen
# automatically until the DKMS at24 module is rebuilt for kernel 6.8.
_NVMEM_PATH = '/sys/bus/nvmem/devices/3-00500/nvmem'

# File-based fallback used when the hardware EEPROM is not accessible.
# Stored under ~/.config so the running user always has write permission.
_FALLBACK_PATH = os.path.expanduser('~/.config/mini_pupper_bsp/servo_calibration.pkl')


def _active_path():
    """Return the hardware EEPROM path if it exists, else the file fallback."""
    if os.path.exists(_NVMEM_PATH):
        return _NVMEM_PATH
    return _FALLBACK_PATH


def write(data):
    path = _active_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as fd:
        pickle.dump(data, fd, protocol=pickle.HIGHEST_PROTOCOL)


def read():
    with open(_active_path(), 'rb') as fd:
        return pickle.load(fd)
