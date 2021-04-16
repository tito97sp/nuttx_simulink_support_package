function portName = getHostSerialPortForFirmwareUpload(configData,hObj)
% GETHOSTSERIALPORTFORFIRMWAREUPLOAD Get the host serial port name used for firmware upload.

%  Copyright 2020 The MathWorks, Inc.
targetHW =  hObj.get_param('HardwareBoard');
autodetectBoard= false;
if  ~strcmp(targetHW, message('px4:hwinfo:PixhawkSeries').getString)
    if configData.Automatic_Serial_Scan == 1
        autodetectBoard = true;
    end
end
if strcmp(targetHW, message('px4:hwinfo:PixhawkSeries').getString) || ~autodetectBoard
    portName = configData.COM_Upload_Storage;
else
    portName = px4.internal.util.CommonUtility.getCOMPort(targetHW);
    portName = px4.internal.util.CommonUtility.verifyCOMPort(portName,targetHW);
end
end