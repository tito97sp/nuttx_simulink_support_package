function openParameterReferencePage(~,~,~,~)
% OPENPARAMETERREFERENCEPAGE
% This is a 'View PX4 parameters' callback function opens px4 parameter reference page for
% Pixhawk Series boards

% Copyright 2018-2020 The MathWorks, Inc.
web('https://dev.px4.io/v1.10/en/advanced/parameter_reference.html','-browser');
end
