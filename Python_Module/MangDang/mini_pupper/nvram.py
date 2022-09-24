import pickle

ServoCalibrationFilePath = '/sys/bus/nvmem/devices/3-00500/nvmem'


def write(data):
    with open(ServoCalibrationFilePath, 'wb') as fd:
        pickle.dump(data, fd, protocol=pickle.HIGHEST_PROTOCOL)


def read():
    with open(ServoCalibrationFilePath, 'rb') as fd:
        return pickle.load(fd)
