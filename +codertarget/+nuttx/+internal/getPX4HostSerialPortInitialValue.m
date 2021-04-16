function value = getPX4HostSerialPortInitialValue(hObj)
% GETEXTERNALSERIALPORTNAME Get the initial serial port name for uploading.

%  Copyright 2018-2020 The MathWorks, Inc.

if ispc
    value = 'COM6';
elseif ismac
    value = '/dev/cu.usbmodem1' ;
elseif isunix
    value = '/dev/ttyACM0' ;
end

if codertarget.target.isCoderTarget(hObj.getConfigSet())
    fieldName = 'COM_Upload_Storage';
    data = codertarget.data.getData(hObj);
    
    if isfield(data, fieldName)
        currentValue = data.(fieldName);
        if validSerialPortName(currentValue)
            value = data.(fieldName);
        else
            data.(fieldName) = value;
            codertarget.data.setData(hObj, data);
        end
    else
        data.(fieldName) = value;
        codertarget.data.setData(hObj, data);
    end
    
end
end

function isValid = validSerialPortName(port)
isValid = false;
if ispc
    isValid = contains(port, 'COM');
elseif ismac
    isValid = contains(port, 'cu.usbmodem');
elseif isunix
    isValid = contains(port, 'tty');
end
end
