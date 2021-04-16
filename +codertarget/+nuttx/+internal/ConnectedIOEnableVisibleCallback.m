function returnValue = ConnectedIOEnableVisibleCallback(hObj)
% ConnectedIOHardwareSerialPortVisibleCallback Configures the set target serial port option

% Copyright 2021 The MathWorks, Inc.

returnValue = 0;
if codertarget.target.isCoderTarget(hObj.getConfigSet())
    data = codertarget.data.getData(hObj);
    if (data.SimulinkIO.Enable_SimulinkIO == 1)
        returnValue =  1;
    end
end
end
