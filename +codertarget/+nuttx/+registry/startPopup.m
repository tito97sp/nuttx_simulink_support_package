function startPopup(hObj)
%startPopup - Opens a message box prompting the user to start Simulink
%Plant model simulation.
%   Copyright 2020 The MathWorks, Inc.

data = codertarget.data.getData(hObj);
%Show msgbox only if the selected Simulator is 'Simulink'
%Do nothing if the selected simulator is jMAVSim
if strcmp(data.simulator,message('px4:hwinfo:Simulink_Simulator').getString)
    uiwait(msgbox(message('px4:general:StartPopupMessage').getString,...
        message('px4:general:StartPopupTitle').getString,'modal'));
end
end