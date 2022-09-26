class HardwareInterface:
    def __init__(self):
        self.log_file = '/tmp/HardwareInterface.log'

    def set_actuator_postions(self, joint_angles):
        with open(self.log_file, 'a') as fh:
            fh.write("%s\n" % joint_angles)
