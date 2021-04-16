function returnValue = PWMRateVisibilityCallback(hObj, groupTag)
% PWMRateVisibilityCallback Configures the option for setting frequency for
% PWM groups

% Copyright 2018-2019 The MathWorks, Inc.

returnValue = 0;
hCS = hObj.getConfigSet() ;
if codertarget.target.isCoderTarget(hCS)
    periph_name = groupTag;
    data = codertarget.data.getData(hObj);
    if isfield(data, periph_name) 
        returnValue = isequal(data.(periph_name), 0);
    end
end
end
