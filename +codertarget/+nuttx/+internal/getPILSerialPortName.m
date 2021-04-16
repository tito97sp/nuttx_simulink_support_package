function port_name = getPILSerialPortName(hObj)
% GETPILSERIALPORTNAME Get the serial port name for PIL.

%  Copyright 2019-2021 The MathWorks, Inc.

data = codertarget.data.getData(hObj);
if (data.PILSerialPort_Checkbox == 1)
    port_name = codertarget.pixhawk.internal.getHostSerialPortForFirmwareUpload(data,hObj);
else
    port_name = data.PILHostCOMPort;
end
end
