function cmakeValue = setCmakeConfigValue(hObj)
% Set Cmake Config value in Target hardware resources.

%  Copyright 2018-2020 The MathWorks, Inc.

cmakeValue = codertarget.pixhawk.internal.getPX4CmakeConfig;

if codertarget.target.isCoderTarget(hObj.getConfigSet())
    %preserveDirty = Simulink.PreserveDirtyFlag(bdroot,'blockDiagram');   %#ok<NASGU>
    fieldName = 'cmakeConfig';
    data = codertarget.data.getData(hObj);
    if isempty(cmakeValue)
        data.(fieldName) = '';
    else
        data.(fieldName) = cmakeValue;
    end
    codertarget.data.setData(hObj, data);
end
end
