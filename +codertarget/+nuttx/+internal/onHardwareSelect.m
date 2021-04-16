function onHardwareSelect( hCS, ~ )
%This function is for internal use only. It may be removed in the future.

%ONHARDWARESELECT Executed when PX4 hardware is selected
%   See also codertarget.pixhawk.internal.onHardwareDeselect

% Copyright 2018-2020 The MathWorks, Inc.

validateattributes(hCS, {'Simulink.ConfigSet'}, {'nonempty'});

% Note: The setProp commands below will work even if the properties are
% already disabled

%Set code generation language to C++
val = getProp(hCS, 'TargetLang');
if ~strcmpi(val, 'C++')
    setProp(hCS, 'TargetLang', 'C++');
    set_param(hCS, 'CodeInterfacePackaging','Nonreusable function');
end

set_param(hCS, 'SimTargetLang', 'C++');

% Use positive priority order
set_param(hCS,'PositivePriorityOrder','on');
% Enable multi-tasking by default but do NOT lock setting
set_param(hCS,'EnableMultiTasking','on')

% change Ext Mode Trig Duration at Target Selection
set_param(hCS.getModel,'ExtModeTrigDuration',10);

% Support long long for uint64 support
set_param(hCS,'ProdLongLongMode','on');

% Lock down properties so that they cannot be accidentally modified by the
% user.
%
% NOTE: When disabling properties here, be sure to enable them
% in onHardwareDeselect

hCS.setPropEnabled('TargetLang', false);
hCS.setPropEnabled('PositivePriorityOrder', false);

data = codertarget.data.getData(hCS);
if isfield(data, 'TargetHardware')
    targetHardware = data.TargetHardware;
    if strcmp(targetHardware,  message('px4:hwinfo:PX4HostTarget').getString)
        set_param(hCS,'PortableWordSizes','on');
        set_param(hCS, 'ExtModeStaticAllocSize', 1000000);
    else
        set_param(hCS,'PortableWordSizes','off');
        % Set external mode logging buffer depth for hardware boards
        set_param(hCS, 'ExtModeStaticAllocSize', 1024);
    end
end

% Disable SaveState and SaveFinalState for SD card logging as it is not
% part of memory estimation script
set_param(hCS, 'SaveState', 'off');
hCS.setPropEnabled('SaveState',false);
set_param(hCS, 'SaveFinalState', 'off');
hCS.setPropEnabled('SaveFinalState',false);

end
