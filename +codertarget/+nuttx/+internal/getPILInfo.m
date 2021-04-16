function [baudRate, hardwareSerialPort] = getPILInfo(hObj)
% Get the baud rate and hardware serial port for the PIL.

%  Copyright 2019-2020 The MathWorks, Inc.

data = codertarget.data.getData(hObj);
% PIL is supported over /dev/ttyACM0 only
hardwareSerialPort = '/dev/ttyACM0';
baudRate = data.ttyACM0.BaudRate;
end
