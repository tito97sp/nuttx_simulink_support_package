function closePinMap( ActionData,~)
%CLOSEPINMAP close the Pin Map for selected Pixhawk series board

% Copyright 2018-2020 The MathWorks, Inc.
pinMap_h = [];
if isfield(ActionData.UserData, 'h')
    pinMap_h = ActionData.UserData.h;
end
if ~isempty(pinMap_h) && isvalid(pinMap_h)
    close(pinMap_h);
    ActionData.UserData.h = [];
end
end
