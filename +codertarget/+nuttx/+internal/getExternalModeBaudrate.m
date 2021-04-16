function baudRate = getExternalModeBaudrate(hObj)
% Get the baud rate for the External mode serial port.

%  Copyright 2018-2019 The MathWorks, Inc.

[baudRate, ~] = codertarget.pixhawk.internal.getExternalModeInfo(hObj);
end
