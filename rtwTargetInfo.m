function rtwTargetInfo(tr)
%RTWTARGETINFO Register toolchain

% Copyright 2018-2020 The MathWorks, Inc.
    tr.registerTargetInfo(@loc_createToolchain);
    % tr.registerTargetInfo(@loc_createPILConfig);
    codertarget.TargetRegistry.addToTargetRegistry(@loc_registerThisTarget);
    codertarget.TargetBoardRegistry.addToTargetBoardRegistry(@loc_registerBoardsForThisTarget);
end

%--------------------------------------------------------------------------
function config = loc_createToolchain
    rootDir = fileparts(mfilename('fullpath'));
    config = coder.make.ToolchainInfoRegistry; % initialize
    arch = computer('arch') ;
    config(end).Name           = 'GNU Tools for Nuttx based boards';
    config(end).Alias          = ['GNU_NUTTX_' upper(arch)]; % internal use only
    config(end).FileName       = fullfile(rootDir, ['gnu_gcc_px4_embedded_gmake_' arch '_v7.2.1.mat']);
    config(end).TargetHWDeviceType = {'*'};
    config(end).Platform           = {arch};

end


function ret = loc_registerThisTarget()
    ret.Name = 'nuttx';
    [targetFilePath, ~, ~] = fileparts(mfilename('fullpath'));
    ret.TargetFolder = targetFilePath;
    ret.TargetType = 0; % Value 0 indicates Embedded Coder target
end

%PIL Config  ------------------------------------------------------------------------
% function config = loc_createPILConfig
%     config(1) = rtw.connectivity.ConfigRegistry;
%     config(1).ConfigName = 'PX4 Autopilot';
%     config(1).ConfigClass = 'codertarget.pixhawk.pil.SerialConnectivityConfig';
%     config(1).isConfigSetCompatibleFcn = @i_isConfigSetCompatible;
% end

% -------------------------------------------------------------------------
function boardInfo = loc_registerBoardsForThisTarget()
    target = 'nuttx';
    [targetFolder, ~, ~] = fileparts(mfilename('fullpath'));
    boardFolder = codertarget.target.getTargetHardwareRegistryFolder(targetFolder);
    boardInfo = codertarget.target.getTargetHardwareInfo(targetFolder, boardFolder, target);
end

function isConfigSetCompatible = i_isConfigSetCompatible(configSet)
    isConfigSetCompatible = false;
    if configSet.isValidParam('CoderTargetData')
        coderTargetData =  configSet.getParam('CoderTargetData');
        isConfigSetCompatible = (isequal(coderTargetData.TargetHardware , message('nuttx:hwinfo:stm32h7_nuttx').getString));
    end
end
% LocalWords: toolchain NUTTX gmake codertarget pixhawk pil Pixhawk Pixracer Crazyflie
% [EOF]
