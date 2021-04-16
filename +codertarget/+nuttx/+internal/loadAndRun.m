function loadAndRun(hCS,executableFile,targetHardware,varargin)

%

%   Copyright 2018-2020 The MathWorks, Inc.

buildDir = px4.internal.util.CommonUtility.getPX4FirmwareBuildDir;
px4_base_dir = codertarget.pixhawk.internal.getPX4BaseDir();
firmwareUploadScript = fullfile(px4_base_dir,'Firmware','Tools','px_uploader.py');
ConfigCMake = codertarget.pixhawk.internal.getPX4CmakeConfig;

p = inputParser;
p.addOptional('firmwareImagePath', fullfile(buildDir ,[ConfigCMake,'.px4']));
parse(p,varargin{:});
firmwareImagePath = RTW.transformPaths(p.Results.firmwareImagePath);

CoderTargetStruct = codertarget.data.getData(hCS);

% Copy and rename the generated .elf to be parsed by XCP External Mode
% Target handler
if coder.internal.xcp.isXCPOnSerialTarget(hCS) 
    [exePath, exeName, ~] = fileparts(executableFile);
    % The executable name is dummy name '<modelName>.pre'. Replace '.pre'
    % with '.elf' to obtain destination elf Name as required by XCP
    elfName = [erase(exeName, '.pre') '.elf'];
    newELfPath = fullfile(exePath, elfName);
    generatedPX4Executable = fullfile(buildDir ,[ConfigCMake,'.elf']);
    if isfile(generatedPX4Executable)
        copyfile(generatedPX4Executable, newELfPath);
    else
        error(message('px4:general:PX4ExecutableNotFound').getString);
    end
end

if(strcmp(get_param(hCS,"MatFileLogging"),'on'))
    % Error out if the size for bss + data exceeds 50% of total RAM
    
    elf = [ConfigCMake,'.elf'];%'px4_fmu-v2_default.elf'
    elfpath = fullfile(buildDir,elf);
    fwVersion = px4.internal.util.CommonUtility.getPX4FirmwareVersion();
    if(strcmp(fwVersion,'v1.10.2'))
        if(ispc)
            toolchainDir = fullfile(codertarget.pixhawk.internal.getPX4CygwinDir,'toolchain','gcc-arm','bin');
            gccarmsize = fullfile(toolchainDir,'arm-none-eabi-size.exe');
        else
            %For unix
            [~, homeFolder] = system('echo $HOME');
            toolchainDir = [strip(homeFolder) '/gcc-arm-none-eabi-7-2017-q4-major/bin'];
            if ~isfolder(toolchainDir)
                toolchainDir = '/opt/gcc-arm-none-eabi-7-2017-q4-major/bin';
                if ~isfolder(toolchainDir)
                    %assume gcc toolchain is on path and hence providing
                    %full path is not required
                    toolchainDir = '';
                end
            end
            gccarmsize = fullfile(toolchainDir,'arm-none-eabi-size');
        end
        size = getSizeofElf(gccarmsize,elfpath);
        %Error out if the total .elf memory is greater than half of the board's memory
        boardRam = px4.internal.util.CommonUtility.getBoardRAM(targetHardware);
        if(size > boardRam/2)
            error(message('px4:general:SDCardMemoryError', num2str(size),targetHardware).getString);
        end
    else
        px4.internal.util.CommonUtility.localizedError('px4:general:FirmwareVersionCheck');
    end
end

% Check if the autopilot is still connected
COM_PortToUse = codertarget.pixhawk.internal.checkIfAutopilotIsConnected(hCS, targetHardware);

if ispc
    % Validate if any other application (such as QGC) is open that is using the same port
    % In Debian 9, the following code causes the COM port to change. Hence
    % disabling the code for Linux.
    px4UploadSerialObj = serial(COM_PortToUse, 'BaudRate', 57600 ) ;
    try
        fopen(px4UploadSerialObj);
    catch
        fclose(px4UploadSerialObj) ;
        clear('px4UploadSerialObj') ;
        px4.internal.util.CommonUtility.localizedError('px4:general:COMPortInUse', COM_PortToUse);
    end
    fclose(px4UploadSerialObj) ;
    clear('px4UploadSerialObj') ;
end

disp(message('px4:general:SerialPortUsedForUpload', COM_PortToUse).getString) ;

if ispc
    pythonApp = fullfile(codertarget.pixhawk.internal.getPythonRootDir,'python.exe');
elseif ismac
    pythonApp = 'python';
elseif isunix
    pythonApp = 'python';
end

% Reboot the board
NuttxPortToUse = CoderTargetStruct.Nuttx_Serial_Port ;
if isempty(NuttxPortToUse)
    uiwait(msgbox(message('px4:general:MsgBoxDescription').getString, message('px4:general:MsgBoxTitle').getString,'modal'));
else
    disp(message('px4:general:SerialPortUsedForNuttx', NuttxPortToUse).getString) ;
    
    px4SerialObj =  serial(NuttxPortToUse, 'BaudRate', 57600 ) ; %#ok<*SERIAL>
    try
        fopen(px4SerialObj) ;
        fwrite(px4SerialObj, 13)                  % Send carriage return
        pause(3);
        result = char(fread(px4SerialObj, 10))' ;  %#ok<FREAD>
        if contains(result, 'nsh')
            fwrite(px4SerialObj, ['reboot' 13]) ;
            pause(1) ;
        else
            uiwait(msgbox(message('px4:general:MsgBoxDescription').getString, message('px4:general:MsgBoxTitle').getString,'modal'));
        end
    catch
        uiwait(msgbox(message('px4:general:MsgBoxDescription').getString, message('px4:general:MsgBoxTitle').getString,'modal'));
    end
    fclose(px4SerialObj) ;
    clear('px4SerialObj') ;
end

if isfield(CoderTargetStruct, 'forceUpload_Checkbox')
    forceUpload = CoderTargetStruct.forceUpload_Checkbox;
else
    forceUpload = 0;
end
firmwareUploadCmd = px4.internal.util.CommonUtility.getfirmwareUploadCmd(pythonApp,firmwareUploadScript,COM_PortToUse,firmwareImagePath, forceUpload);
[uploadStatus, uploadMsg] = system(firmwareUploadCmd, '-echo');

if uploadStatus
    error(message('px4:general:FirmwareUploadFailed', uploadMsg).getString);
else
    if contains(uploadMsg, message('px4:general:TimeoutDlg').getString)
        error(message('px4:general:fwUploadIssue_Timeout').getString);
    elseif contains(uploadMsg, message('px4:general:fmuv2BootloaderDlg').getString)
        error(message('px4:general:fwUploadIssue').getString);
    end
end

end

function size = getSizeofElf(gccarmsize,elfpath)
[s,r] = system([gccarmsize,' ',elfpath]);
if(~s)
    cell_r = strsplit(r);
    %For ex - The contents of cell_r (of length 14) are
    %{'','text','data','bss','dec','hex','filename','1561715','3864','27332','1592911','184e4f','C:\px4_180_c\Firmware\build\nuttx_px4fmu-v4_default\nuttx_px4fmu-v4_default.elf',''}
    %The 1st and 14th data is empty char. 2nd to 7th represent the variable
    %names, and 8th to 13th represent the corresponding values.
    %Add the .data(9th element) and .bss(10th element) segments to get the total size
    size = str2double(cell_r{10}) + str2double(cell_r{9});
    % Get size in KB
    size = size/1024;
else
    px4.internal.util.CommonUtility.localizedError('px4:general:SystemCommandFail');
end
end
