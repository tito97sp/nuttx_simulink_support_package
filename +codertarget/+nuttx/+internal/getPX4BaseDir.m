function out = getPX4BaseDir
%

%   Copyright 2018-2020 The MathWorks, Inc.
lName = 'PX4 Base';
out = [];
targetFolder = codertarget.target.getTargetFolder('px4');
tpFileName = codertarget.target.getThirdPartyToolsRegistrationFileName(targetFolder);
if exist(tpFileName, 'file')
    h = codertarget.thirdpartytools.ThirdPartyToolInfo(tpFileName,false);
    thirdPartyToolsInfo = h.getThirdPartyTools();
    thirdPartyToolsInfo = [thirdPartyToolsInfo{:}];
    thirdPartyToolsInfo = [thirdPartyToolsInfo{:}];
    idx = ismember({thirdPartyToolsInfo.ToolName}, lName);
    out = thirdPartyToolsInfo(idx).RootFolder;
end
end
