function visibility = ExtModeLoggingBufferVisibleCallback(hObj)
% Callback to make the logging buffer size visible for only XCP External
% mode

% Copyright 2020 The MathWorks, Inc.

visibility=0;
if(isfield(hObj.CoderTargetData, 'ConnectionInfo'))
    extModeInterface = codertarget.data.getParameterValue(hObj,'ExtMode.Configuration');
    visibility = strcmp(extModeInterface,'XCP on TCP/IP') || ...
                strcmp(extModeInterface,'XCP on Serial');
end
end
