function setExtModeLoggingBufferSize(hObj, hDlg, tag, ~)
% Callback to set the XCP External Mode logging buffer size

%   Copyright 2020 The MathWorks, Inc.

    hCS = hObj.getConfigSet();

    % Save existing 'ExtModeStaticAllocSize'
    oldBufferDepth = get_param(hCS, 'ExtModeStaticAllocSize');
    t800 = onCleanup(@()cleanup(hCS, oldBufferDepth));

    % Get new buffer depth
    newBufferDepth = str2double( hDlg.getWidgetValue(tag) );

    % Set new value to 'ExtModeStaticAllocSize' and 'ExtMode.signalBufferSize'
    codertarget.data.setParameterValue(hCS, 'ExtMode.signalBufferSize', newBufferDepth);
    set_param(hCS, 'ExtModeStaticAllocSize', newBufferDepth);

    return;

end

% If we somehow end up in a situation where 'ExtMode.signalBufferSize' and
% 'ExtModeStaticAllocSize' not same, revert.
function cleanup(hCS, existingBufferDepth)
    if( get_param(hCS, 'ExtModeStaticAllocSize') ...
            ~= codertarget.data.getParameterValue(hCS, 'ExtMode.signalBufferSize'))
        codertarget.data.setParameterValue(hCS, 'ExtMode.signalBufferSize', existingBufferDepth);
    end
end
