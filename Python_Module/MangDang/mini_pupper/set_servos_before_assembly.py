from MangDang.mini_pupper.HardwareInterface import HardwareInterface
import numpy as np


def get_motor_name(i, j):
    motor_type = {0: "abduction", 1: "inner", 2: "outer"}  # Top  # Bottom
    leg_pos = {0: "front-right", 1: "front-left", 2: "back-right", 3: "back-left"}
    final_name = motor_type[i] + " " + leg_pos[j]
    return final_name


def get_motor_setpoint(i, j):
    data = np.array([[0, 0, 0, 0], [45, 45, 45, 45], [-45, -45, -45, -45]])
    return data[i, j]


def degrees_to_radians(input_array):
    """Converts degrees to radians.

    Parameters
    ----------
    input_array :  Numpy array or float
        Degrees

    Returns
    -------
    Numpy array or float
        Radians
    """
    return input_array * np.pi / 180.0


def radians_to_degrees(input_array):
    """Converts degrees to radians.

    Parameters
    ----------
    input_array :  Numpy array or float
        Radians

    Returns
    -------
    Numpy array or float
        Degrees
    """
    return input_array * 180.0 / np.pi


def calibrate_angle_offset(hardware_interface):
    """Calibrate the angle offset for the twelve motors on the robot. Note that servo_params is modified in-place.
    Parameters
    ----------
    servo_params : ServoParams
        Servo parameters. This variable is updated in-place.
    pi_board : Pi
        RaspberryPi object.
    pwm_params : PWMParams
        PWMParams object.
    """

    hardware_interface.servo_params.neutral_angle_degrees = np.zeros((3, 4))

    for leg_index in range(4):
        for axis in range(3):
            set_point = get_motor_setpoint(axis, leg_index)

            # Zero out the neutral angle
            hardware_interface.servo_params.neutral_angle_degrees[axis, leg_index] = 0

            # Move servo to set_point angle
            hardware_interface.set_actuator_position(
                degrees_to_radians(set_point),
                axis,
                leg_index,
            )


def main():
    """Main program
    """
    hardware_interface = HardwareInterface()

    calibrate_angle_offset(hardware_interface)


if __name__ == "__main__":
    main()
