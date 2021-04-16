function COM_PortToUse = checkIfAutopilotIsConnected(hCS, targetHardware)
% checkIfAutopilotIsConnected checks if the selected PX4 Autopilot in the
% Simulink Config set is connected to the host computer. If the autopilot
% is found to be connected, the corresponding COM Port is returned. If no
% such COM port is found, an error is thrown pro-actively so that user's
% don't get this error till the Firmware build completes which might take a
% significant time.

%   Copyright 2020 The MathWorks, Inc.

CoderTargetStruct = codertarget.data.getData(hCS);
autodetectBoard= false;
if  ~strcmp(targetHardware, message('px4:hwinfo:PixhawkSeries').getString)
    if CoderTargetStruct.Automatic_Serial_Scan == 1
        autodetectBoard = true;
    end
end

if strcmp(targetHardware,message('px4:hwinfo:PixhawkSeries').getString) || ~autodetectBoard
    COM_PortToUse = CoderTargetStruct.COM_Upload_Storage ;
    if isempty(COM_PortToUse)
        px4.internal.util.CommonUtility.localizedError('px4:general:SerialPortEmpty');
    else
        usbDevices = matlab.hwmgr.internal.hwconnection.USBDeviceEnumerator;
        COMPortFound = usbDevices.getSerialPorts() ;
        if ~ismember(COM_PortToUse, COMPortFound)
            px4.internal.util.CommonUtility.localizedError('px4:general:COMPortNotFound', COM_PortToUse);
        end
    end
else
    COM_PortToUse = px4.internal.util.CommonUtility.getCOMPort(targetHardware);
    COM_PortToUse = px4.internal.util.CommonUtility.verifyCOMPort(COM_PortToUse,targetHardware);
end

end
