function rtwTargetInfo(tr)
target = loc_registerThisTarget();
codertarget.target.checkReleaseCompatibility(target);
codertarget.TargetRegistry.addToTargetRegistry(@loc_registerThisTarget);
codertarget.TargetBoardRegistry.addToTargetBoardRegistry(@loc_registerBoardsForThisTarget);
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
