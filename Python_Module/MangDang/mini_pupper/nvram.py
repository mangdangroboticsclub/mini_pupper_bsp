import os
import pickle

# EEPROM nvmem path: 3-00500 (Jammy) or 3-00501 (Noble)


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
