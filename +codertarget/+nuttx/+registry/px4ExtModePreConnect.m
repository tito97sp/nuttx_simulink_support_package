function px4ExtModePreConnect(hCS)
% This utility is called by External mode infra just before Connect
% operation. Two tasks happen here, 
% 1. Wait for target to boot up
% 2. Set the correct ExtModeMexArgs required by XCP

% Copyright 2020 The MathWorks, Inc.

modelName = get(getModel(hCS),'Name');

% XCP on Serial for Pixhawk Hardware
if coder.internal.xcp.isXCPOnSerialTarget(hCS)
    % Wait for hardware to boot up
    pause(10);
    extmodeMexArgs = get_param(hCS, 'ExtModeMexArgs');
    extModeArgsArray=strsplit(extmodeMexArgs);
    
    % By default symbols file name is located in the PX4 Firmware build
    % directory
    symbolsFileName = [modelName '.elf'];
    buildDir = RTW.getBuildDir(modelName);
    assert(~isempty(buildDir), 'invalid build directory');
    % expected Symbol file name which will be copied by loadAndRun.m
    symbolsFileName = fullfile(buildDir.CodeGenFolder, symbolsFileName);
    
    % Append the extra parameters to the extmodeMexArgs
    % The format is 0 COMPort Baudrate modelName.elf
    extmodeMexArgs = sprintf('%s ''%s'' %s ''%s''', extModeArgsArray{1}, extModeArgsArray{2},...
        extModeArgsArray{3}, symbolsFileName);
    
    set_param(hCS, 'ExtModeMexArgs', extmodeMexArgs);
    
elseif coder.internal.xcp.isXCPOnTCPIPTarget(hCS)
    % XCP on TCP/IP for PX4 Host Target
    % Wait for PX4 Host Target to start
    pause(10);
    extmodeMexArgs = get_param(hCS, 'ExtModeMexArgs');
    extModeArgsArray=strsplit(extmodeMexArgs);
    executableExtension = '';
    if ispc
        executableExtension = '.exe';
    end
    % By default symbols file name is located in the PX4 Firmware build
    % directory/bin
    symbolsFileName = [modelName executableExtension];
    buildDir = RTW.getBuildDir(modelName);
    assert(~isempty(buildDir), 'invalid build directory');
    symbolsFileName = fullfile(buildDir.CodeGenFolder, symbolsFileName);
    
    % Append the extra parameters to the extmodeMexArgs
    % The format is 0 IP Port modelName.elf
    extmodeMexArgs = sprintf('%s %s %s ''%s''', extModeArgsArray{1}, extModeArgsArray{2},...
        extModeArgsArray{3}, symbolsFileName);
    
    set_param(hCS, 'ExtModeMexArgs', extmodeMexArgs);
    
else
    % Wait for hardware to boot up
    pause(10);
    %Classical External Mode, throw deprecation warning
    warning(message('px4:general:ExtModeWarning'));
    
end
end

