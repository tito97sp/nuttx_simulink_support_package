function setupPX4Firmware(hCS)

%

%   Copyright 2019-2020 The MathWorks, Inc.

configSetData = codertarget.data.getData(hCS);

px4Setup = px4.internal.fwsetup.PX4FirmwareSetup.getInstance(strrep(configSetData.cmakeConfig, 'posix', 'px4'));
px4Setup.modifyCmakeIfNeeded();
px4Setup.modifyStartupScriptIfNeeded();
px4Setup.register3pTokensFromSimulink();

end
