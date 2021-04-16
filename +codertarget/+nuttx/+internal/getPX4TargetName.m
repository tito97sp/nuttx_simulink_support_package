function [targetname,hCS] = getPX4TargetName()
%GETPX4TARGETNAME Return the current PX4 Target Name and Configset

% Copyright 2020 The MathWorks, Inc.

targetname = '';
hCS = getActiveConfigSet(bdroot);
tgtInfo = codertarget.targethardware.getTargetHardware(hCS);
if isa(tgtInfo,'codertarget.targethardware.TargetHardwareInfo')
    targetname = tgtInfo.Name;
end
end
