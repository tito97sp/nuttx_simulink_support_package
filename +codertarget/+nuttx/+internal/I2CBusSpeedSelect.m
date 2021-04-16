function ret = I2CBusSpeedSelect(hObj, Module)
%I2CBusSpeedSelect Set the Bus speed value for the selected I2C module

% Copyright 2020 The MathWorks, Inc.

if codertarget.target.isCoderTarget(hObj.getConfigSet())
    
    I2Cdata = codertarget.data.getParameterValue(hObj,'I2C');
    switch Module
        case 'I2C1'
            ret = I2Cdata.Bus1SpeedkHz_index;
        case 'I2C2'
            ret = I2Cdata.Bus2SpeedkHz_index;
        case 'I2C3'
            ret = I2Cdata.Bus3SpeedkHz_index;
        case 'I2C4'
            ret = I2Cdata.Bus4SpeedkHz_index;
        otherwise
            ret =1;
    end      

end
end
