function portName = getConnectedIOHostSerialPort(hObj)
% GETCONNECTEDIOSERIALPORTNAME Get the host serial port name for ConnectedIO.

%  Copyright 2021 The MathWorks, Inc.

data = codertarget.data.getData(hObj);

if (data.ConnectedIOSerialPort_Checkbox == 1)
    configData = codertarget.data.getData(hObj);
    portName = codertarget.pixhawk.internal.getHostSerialPortForFirmwareUpload(configData,hObj);
else
    portName = data.ConnectedIOHostCOMPort;
end
end
