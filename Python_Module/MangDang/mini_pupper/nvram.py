import os
import pickle


def _get_nvmem_path():
    for path in [
        '/sys/bus/nvmem/devices/3-00501/nvmem',  # Noble
        '/sys/bus/nvmem/devices/3-00500/nvmem',  # Jammy
    ]:
        if os.path.exists(path):
            return path
    return '/sys/bus/nvmem/devices/3-00500/nvmem'


ServoCalibrationFilePath = _get_nvmem_path()


def write(data):
    with open(ServoCalibrationFilePath, 'wb') as fd:
        pickle.dump(data, fd, protocol=pickle.HIGHEST_PROTOCOL)


def read():
    with open(ServoCalibrationFilePath, 'rb') as fd:
        return pickle.load(fd)
