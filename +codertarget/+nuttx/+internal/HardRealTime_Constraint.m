function ret = HardRealTime_Constraint(hObj)
%HardRealTime_Constraint
%This is a callback function used by the coder target UI

%   Copyright 2018-2019 The MathWorks, Inc.

ret = 0;
if codertarget.target.isCoderTarget(hObj.getConfigSet())
    data = codertarget.data.getData(hObj);
    ret = data.HRT_Constraint;    
end
end
