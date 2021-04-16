function val = getRegistrationTags()
%getRegistrationTags - Return the registration tags used by all the
%blocks in the PX4 library

%   Copyright 2021 The MathWorks, Inc.


blockRegTags = {
    'I2C_Master_Read'
    'I2C_Master_Write'
    'PX4_Analog_Input'
    'PX4_PWM_Output'
    'Accelerometer'
    'Battery'
    'GPS'
    'Gyroscope'
    'Magnetometer'
    'Radio_Control_Transmitter'
    'Vehicle_Attitude'
    'PX4_uORB_Message'
    'PX4_uORB_Read'
    'PX4_uORB_Write'
    'Read_Parameter'
    'Serial_Receive'
    'Serial_Transmit'
    }';

val = blockRegTags';
end
