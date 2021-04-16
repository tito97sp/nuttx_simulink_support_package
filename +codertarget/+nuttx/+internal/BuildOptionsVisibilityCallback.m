function returnValue = BuildOptionsVisibilityCallback(hObj)
% BuildOptionsVisibilityCallback Configures the option for Build and Build,
% load and run

% Copyright 2018-2019 The MathWorks, Inc.

returnValue = 0;
hCS = hObj.getConfigSet() ;
if codertarget.target.isCoderTarget(hCS)
    periph_name = 'Runtime';
    param_name = 'BuildAction';
    data = codertarget.data.getData(hObj);
    if isfield(data, periph_name) && isfield(data.(periph_name), param_name)
        loadAndRunEnabled = strcmp(data.(periph_name).(param_name), "Build, load and run");
        if(loadAndRunEnabled)
            returnValue = 1;
        end
    end
end
end
