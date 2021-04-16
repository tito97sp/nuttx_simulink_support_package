function port_name = getExternalSerialPortName(hObj)
% GETEXTERNALSERIALPORTNAME Get the serial port name for the external mode.

%  Copyright 2018-2021 The MathWorks, Inc.

data = codertarget.data.getData(hObj);

if (data.extModeSerialPort_Checkbox == 1)
    port_name = codertarget.pixhawk.internal.getHostSerialPortForFirmwareUpload(data,hObj);
else
    port_name = data.ExtModeHostCOMPort;
end
end
