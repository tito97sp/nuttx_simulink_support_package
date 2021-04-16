function onHardwareDeselect( hCS, ~ )
%This function is for internal use only. It may be removed in the future.

%ONHARDWAREDESELECT Executed when PX4 hardware is de-selected
%   See also codertarget.pixhawk.internal.onHardwareSelect

% Copyright 2018-2020 The MathWorks, Inc.

validateattributes(hCS, {'Simulink.ConfigSet'}, {'nonempty'});

% Deselect/enable the properties that were disabled during target selection

hCS.setPropEnabled('TargetLang', true);
setProp(hCS, 'TargetLang', 'C');
set_param(hCS, 'SimTargetLang', 'C');
hCS.setPropEnabled('PositivePriorityOrder', true);
set_param(hCS,'PositivePriorityOrder','off');
set_param(hCS,'EnableMultiTasking','off')
set_param(hCS.getModel,'ExtModeTrigDuration', 1000);
set_param(hCS,'ProdLongLongMode','off');

set_param(hCS,'PortableWordSizes','off');

hCS.setPropEnabled('SaveState',true);
hCS.setPropEnabled('SaveFinalState',true);

%Revert the ExtModeStaticAllocSize to default value
set_param(hCS, 'ExtModeStaticAllocSize', 1000000);

end
