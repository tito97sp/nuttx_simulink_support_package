function [baudRate, hardwareSerialPort] = getExternalModeInfo(hObj)
% Get the baud rate and hardware serial port for the External mode.

%  Copyright 2018-2021 The MathWorks, Inc.

data = codertarget.data.getData(hObj);

hardwareSerialPort = data.ExtSerialPort;

switch hardwareSerialPort
    case '/dev/ttyACM0'
        baudRate = data.ttyACM0.BaudRate;
    case '/dev/ttyS0'
        baudRate = data.ttyS0.BaudRate;
    case '/dev/ttyS1'
        baudRate = data.ttyS1.BaudRate;
    case '/dev/ttyS2'
        baudRate = data.ttyS2.BaudRate;
    case '/dev/ttyS3'
        baudRate = data.ttyS3.BaudRate;
    case '/dev/ttyS4'
        baudRate = data.ttyS4.BaudRate;
    case '/dev/ttyS5'
        baudRate = data.ttyS5.BaudRate;
    case '/dev/ttyS6'
        baudRate = data.ttyS6.BaudRate;
end
end
