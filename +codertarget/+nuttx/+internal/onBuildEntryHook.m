function onBuildEntryHook(hCS)
%ONBUILDENTRYHOOK Entry hook point for code generation

%   Copyright 2018-2021 The MathWorks, Inc.

% Error if External Mode and MatFileLogging is used together
% Warning out if MatFileLogging is enabled for PX4 Host Target
targetHardware = hCS.get_param('HardwareBoard');
if(strcmp(get_param(hCS,'MatFileLogging'),'on'))
    if(strcmp(get_param(hCS,'ExtMode'),'on'))
        px4.internal.util.CommonUtility.localizedError('px4:general:ExtMatFileConflict');
    end
    if strcmp(targetHardware,message('px4:hwinfo:PX4HostTarget').getString)
        px4.internal.util.CommonUtility.localizedWarning('px4:general:MatFileSITLConflict');
    end
end
% Check that target language is C++ and error out if it is not
targetLang = getProp(hCS, 'TargetLang');
if ~strcmpi(targetLang, 'C++')
    error(message('px4:cgen:CppLanguageRequired', targetLang));
end

rtmErrorStatus = getProp(hCS, 'SuppressErrorStatus');
if strcmpi(rtmErrorStatus, 'on')
    error(message('px4:cgen:rtmErrorStatus'));
end

supportLongLong = getProp(hCS, 'ProdLongLongMode');
if strcmpi(supportLongLong, 'off')
    error(message('px4:cgen:supportLongLong'));
end

isCodePkgCppClass = getProp(hCS, 'CodeInterfacePackaging');
if strcmpi(isCodePkgCppClass, 'C++ class')
    error(message('px4:cgen:isCodePkgCppClass'));
end

CoderTargetUI_data = codertarget.data.getData(hCS);

PX4FirmwarePath = codertarget.pixhawk.internal.getPX4BaseDir;
if isempty(PX4FirmwarePath)
    error(message('px4:general:PX4BaseDirEmpty').getString);
end

% If selected target hardware is not vanilla flavor, we need to validate
% the board against current Cmake value
if ~strcmp(targetHardware, message('px4:hwinfo:PixhawkSeries').getString)
    currentCmake = codertarget.pixhawk.internal.getPX4CmakeConfig;
    validCmake = validateCmakeandPX4Hardware(targetHardware, currentCmake);
    if ~validCmake
        error(message('px4:cgen:incompatibleCmakeHardware', currentCmake, targetHardware));
    end
end

% Create empty lib file, so that build infrastructure for model references
% behaves correctly (it expects to link against <modelName>_rtwlib, but
% that is not needed for PX4 targets.
if exist(fullfile('tmwinternal','minfo_mdlref.mat'),'file')
    loadOutput = load(fullfile('tmwinternal','minfo_mdlref.mat'));
    infoStruct = loadOutput.infoStruct;
    libfilename = [infoStruct.modelName,'_rtwlib.mk'];
    fd = fopen(libfilename,'w');
    fclose(fd);
end

% Add pre-processor for Hard-Real Time Constraint
if isequal(CoderTargetUI_data.HRT_Constraint,1)
    warning (message('px4:general:HRTEnabledWarn').getString);
end

if isfield(CoderTargetUI_data, 'forceUpload_Checkbox')
    if CoderTargetUI_data.forceUpload_Checkbox == 1
        answer = questdlg(message('px4:cgen:MsgBoxDescription').getString,...
            message('px4:cgen:MsgBoxTitle').getString, ...
            message('px4:cgen:ContinueBuild').getString,...
            message('px4:cgen:AbortBuild').getString,...
            message('px4:cgen:AbortBuild').getString);
        switch answer
            case message('px4:cgen:ContinueBuild').getString
                % Don't do anything, continue build
            case message('px4:cgen:AbortBuild').getString
                error(message('px4:cgen:AbortSLBuild').getString);
        end
    end
end

end

function validCmake = validateCmakeandPX4Hardware(targetHardware, cmakeConfig)

workflowObject = matlab.hwmgr.internal.hwsetup.register.PX4Workflow;
supportedCMakes = workflowObject.BoardConfigMap(targetHardware);

if strcmp(targetHardware, message('px4:hwinfo:Pixhawk1').getString)
    % Pixhawk 1 supports fmu-v3 CMake also
    supportedCMakes = [supportedCMakes workflowObject.BoardConfigMap(message('px4:hwinfo:Pixhawk2').getString)];
end

validCmake = any(strcmp(cmakeConfig, supportedCMakes));
end
