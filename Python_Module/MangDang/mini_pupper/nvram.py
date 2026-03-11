import os
import pickle

# Hardware EEPROM path (AT24C08 on I2C bus 3).
# NOTE: Requires the at24 kernel module to be loaded and the DT overlay to
# instantiate the device. On Ubuntu 24.04 / kernel 6.8 this may not happen
# automatically until the DKMS at24 module is rebuilt for kernel 6.8.
#
# The device path varies by kernel version:
#   - Ubuntu 22.04 (Jammy): typically 3-00500
#   - Ubuntu 24.04 (Noble): typically 3-00501 (rmem0 claims 3-00500)


def _detect_nvmem_path():
    """Auto-detect the EEPROM nvmem device path.
    
    Returns the first existing path from the search list, or None if
    no hardware EEPROM device is found.
    """
    patterns = [
        '/sys/bus/nvmem/devices/3-00501/nvmem',  # Noble default
        '/sys/bus/nvmem/devices/3-00500/nvmem',  # Jammy fallback
    ]
    for path in patterns:
        if os.path.exists(path):
            return path
    return None


# Auto-detect at module load time
_NVMEM_PATH = _detect_nvmem_path()

# File-based fallback used when the hardware EEPROM is not accessible.
# Stored under ~/.config so the running user always has write permission.
_FALLBACK_PATH = os.path.expanduser('~/.config/mini_pupper_bsp/servo_calibration.pkl')


def _active_path():
    """Return the hardware EEPROM path if it exists, else the file fallback."""
    if _NVMEM_PATH is not None and os.path.exists(_NVMEM_PATH):
        return _NVMEM_PATH
    return _FALLBACK_PATH


def write(data):
    """Write calibration data to EEPROM or fallback file.
    
    Args:
        data: Dictionary containing calibration parameters
    """
    path = _active_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as fd:
        pickle.dump(data, fd, protocol=pickle.HIGHEST_PROTOCOL)


def read():
    """Read calibration data from EEPROM or fallback file.
    
    Returns:
        Dictionary containing calibration parameters
    """
    with open(_active_path(), 'rb') as fd:
        return pickle.load(fd)
