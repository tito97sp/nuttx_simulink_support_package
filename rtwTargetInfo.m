function rtwTargetInfo(tr)
target = loc_registerThisTarget();
codertarget.target.checkReleaseCompatibility(target);
tr.registerTargetInfo(@loc_createToolchain);
tr.registerTargetInfo(@loc_createPILConfig);
codertarget.TargetRegistry.addToTargetRegistry(@loc_registerThisTarget);
codertarget.TargetBoardRegistry.addToTargetBoardRegistry(@loc_registerBoardsForThisTarget);
end
 
% -------------------------------------------------------------------------
function isConfigSetCompatible =i_isConfigSetCompatible(configSet)
isConfigSetCompatible = false;
if configSet.isValidParam('CoderTargetData')
data = getParam(configSet,'CoderTargetData');
targetHardware = data.TargetHardware;
hwSupportingPIL = { 'Nuttx STM32H743ZI' };
for i=1:numel(hwSupportingPIL)
if isequal(hwSupportingPIL{i},targetHardware)
isConfigSetCompatible = true;
break
end
end
end
end
 
% -------------------------------------------------------------------------
function boardInfo =loc_registerBoardsForThisTarget
target = 'ARM Cortex-M Nuttx Target';
[targetFolder, ~, ~] = fileparts(mfilename('fullpath'));
boardFolder = codertarget.target.getTargetHardwareRegistryFolder(targetFolder);
boardInfo = codertarget.target.getTargetHardwareInfo(targetFolder, boardFolder, target);
end
 
% -------------------------------------------------------------------------
function ret =loc_registerThisTarget
ret.Name = 'ARM Cortex-M Nuttx Target';
[targetFilePath, ~, ~] = fileparts(mfilename('fullpath'));
ret.TargetFolder = targetFilePath;
ret.TargetVersion = 1;
ret.AliasNames = {};
end

%--------------------------------------------------------------------------
function config = loc_createToolchain
rootDir = fileparts(mfilename('fullpath'));
config = coder.make.ToolchainInfoRegistry; % initialize
arch = computer('arch') ;
config(end).Name           = 'Nuttx Toolchain';
config(end).Alias          = 'Nuttx_Toolchain'; % internal use only
config(end).FileName       = fullfile(rootDir, 'gnu_gcc_nuttx_embedded.mat');
config(end).TargetHWDeviceType = {'*'};
config(end).Platform           = {arch};

end


% -------------------------------------------------------------------------
function config =loc_createPILConfig
config(1) = rtw.connectivity.ConfigRegistry;
config(1).ConfigName = 'Nuttx PIL';
config(1).ConfigClass = 'codertarget.nuttx.pil.ConnectivityConfig';
config(1).HardwareBoard = {'Nuttx STM32H743ZI'};
config(1).isConfigSetCompatibleFcn = @i_isConfigSetCompatible;
end

 