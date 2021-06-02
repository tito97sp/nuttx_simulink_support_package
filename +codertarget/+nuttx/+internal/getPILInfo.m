function [baudRate, hardwareSerialPort] = getPILInfo(hObj)
% Get the baud rate and hardware serial port for the PIL.

%  Copyright 2019 The MathWorks, Inc.

data = codertarget.data.getData(hObj);
if (data.PILHardwareSerialPort_Checkbox == 0)
    hardwareSerialPort = data.PILSerialPort;
else
    hardwareSerialPort = data.ExtSerialPort;
end

switch hardwareSerialPort
    case '/dev/ttyACM0'
        baudRate = data.ttyACM0.BaudRate;
    case '/dev/ttyS0'
        baudRate = data.S0.BaudRate;
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

% LocalWords: dev tty ACM
