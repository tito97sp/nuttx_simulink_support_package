function returnValue = PILSerialPortVisibleCallback(hObj)
% PILSerialPortVisibleCallback Configures the set host serial port option

% Copyright 2021 The MathWorks, Inc.

returnValue = 0;
if codertarget.target.isCoderTarget(hObj.getConfigSet())
    data = codertarget.data.getData(hObj);
    if (data.PILSerialPort_Checkbox == 0)
        returnValue =  1;
    end
end
end
