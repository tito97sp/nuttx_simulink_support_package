function returnValue = ExtModeSerialPortVisibleCallback(hObj)
% VisibleUploadCallback Configures the set serial port option

% Copyright 2018-2021 The MathWorks, Inc.

returnValue = 0;
if codertarget.target.isCoderTarget(hObj.getConfigSet())
    data = codertarget.data.getData(hObj);
    if (data.extModeSerialPort_Checkbox == 0)
        returnValue =  1;
    end
end
end
