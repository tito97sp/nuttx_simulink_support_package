function ret = getSemaphoreWaterMark(gcs)
%HardRealTime_Constraint
%This is a callback function used by the coder target UI

%   Copyright 2018-2020 The MathWorks, Inc.

ret = 0;
if codertarget.target.isCoderTarget(getActiveConfigSet(gcs))
    %     data = codertarget.data.getData(hObj);
    data = codertarget.data.getData(getActiveConfigSet(gcs));
    ret = data.SEM_WaterMark;
end
end
