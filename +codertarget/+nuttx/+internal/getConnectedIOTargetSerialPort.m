function targetSerialPort = getConnectedIOTargetSerialPort(~)
% Get the hardware serial port for the ConnectedIO.

%  Copyright 2020 The MathWorks, Inc.

% Connected I/O is supported over /dev/ttyACM0 only
targetSerialPort = '/dev/ttyACM0';

end
