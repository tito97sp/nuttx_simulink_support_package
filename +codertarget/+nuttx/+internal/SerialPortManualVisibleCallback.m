function returnValue = SerialPortManualVisibleCallback(hObj)
% VisibleUploadCallback Configures the set serial port option

% Copyright 2018-2019 The MathWorks, Inc.

returnValue = 0;
if codertarget.target.isCoderTarget(hObj.getConfigSet())
    periph_name = 'Runtime';
    param_name = 'BuildAction';
    data = codertarget.data.getData(hObj);
    if isfield(data, periph_name) && isfield(data.(periph_name), param_name)
        loadAndRunEnabled = strcmp(data.(periph_name).(param_name), "Build, load and run");
    else
        loadAndRunEnabled = false ;
    end
    
    if (loadAndRunEnabled && data.Automatic_Serial_Scan == 0)
        returnValue =  1;
    end
end
end
