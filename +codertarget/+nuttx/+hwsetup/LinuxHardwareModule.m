classdef LinuxHardwareModule < codertarget.pixhawk.hwsetup.HardwareInterface
    % LinuxHardwareModule - Class that covers all hardware specific
    % callbacks in Linux.
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    properties (Constant)
        DEFAULTPX4DOWNLOADUNIX = [ getenv('HOME'),filesep,'src',filesep,'px4'];
    end
    
    properties
        TpPkg
        TokenName
    end
    
    properties (Access = private)
        %To know if Bash shell is present or not
        BashInstalled
    end
    
    methods
        
        function obj = LinuxHardwareModule(varargin)
            obj@codertarget.pixhawk.hwsetup.HardwareInterface();
            %This is required only
            %in Linux as we are adding gcc to path. This is used to verify
            %if toolchain is installed or not.
            codertarget.pixhawk.internal.setupBuildEnvironment();
        end
        
        function BashCmd = getGCCVerScript(~,workflowObject)
            %Execute the getgccver script which tells if the toolchain
            %is installed or not.
            scriptDir = codertarget.pixhawk.internal.getSetupScriptsDir;
            %This is the correct one
            getgccverDir = fullfile(scriptDir,'getgccver.sh');
            logFile = workflowObject.LOGFILE;
            GetGCCVerScript = ['bash ',getgccverDir,' ',logFile];
            
            BashCmd = sprintf('%s',...
                GetGCCVerScript);
        end
        
        function isToolchainInstalled(obj, workflowObject)
            updateGCCVersion(obj, workflowObject);
            gccVersion = getGCCVersion(obj);
            if strcmp(strip(gccVersion), workflowObject.SUPPORTED_GCC_UBUNTU_1804)
                workflowObject.ToolchainInstalled = codertarget.pixhawk.internal.GccVersion.Installed;
            end
        end
        
        function updateGCCVersion(obj, workflowObject)
            gccVerCmd = obj.getGCCVerScript(workflowObject);
            [status,~] = system(gccVerCmd);
            if status
                error(message('px4:hwsetup:SetupPX4Toolchain_Err_ToolchainCheck').getString);
            end
        end%End of updateGCCVersion subfunction
        
        function gccVer = getGCCVersion(~)
            [status,cmd] = system('arm-none-eabi-gcc -dumpversion');
            if status
                gccVer = 'MW_GCCVERSION_NOTPRESENT';
            else
                gccVer = cmd;
            end
        end%End of getGCCVersion method
        
        
        function FWLocation = getDefaultFWLocation(obj)
            FWLocation = codertarget.pixhawk.internal.getPX4BaseDir;
            if isempty(FWLocation)
                FWLocation = obj.DEFAULTPX4DOWNLOADUNIX;
            end
        end%End of getDefaultFWLocation function
        
        function ver = getPX4FirmwareVersion(~,workflowObject)
            currDir = pwd;
            cd(workflowObject.Px4_Firmware_Dir);
            [status,cmdout] = system('git describe --tags');
            cd(currDir);
            if status
                if contains(cmdout,'Not a git repository')
                    error(message('px4:hwsetup:ValidatePX4_FWEmptyErrorLinux').getString);
                else
                    error(message('px4:hwsetup:ValidatePX4_FWVerError',cmdout).getString);
                end
            else
                ver = strip(cmdout);
            end
            
        end%End of getPX4FirmwareVersion method
        
        function updateTpPkg(obj,workflowObject)
            % PX4 Base Root Directory
            obj.TpPkg = obj.createThirdPartyStruct();
            obj.TpPkg.Name = 'PX4 Base';
            obj.TpPkg.RootDir = workflowObject.Px4_Base_Dir;
            obj.TokenName{1} = 'PX4FIRMWAREROOTDIR';
            % CMAKE Config
            obj.TpPkg(2) = obj.createThirdPartyStruct();
            obj.TpPkg(2).Name = 'CMAKE Config';
            obj.TpPkg(2).RootDir = workflowObject.Px4_Cmake_Config;
            obj.TokenName{2} = 'CMAKEMAKECONFIG';
        end%End of updateTpPkg method
        
        function BashCmd = getBuildCommand(~,TargetDir,currDateTime,configFile,logFile)
            
            GitTargetDir = TargetDir;
            scriptDir = codertarget.pixhawk.internal.getSetupScriptsDir;
            %Below is correct
            buildDir = fullfile(scriptDir,'build.sh');
            GitBuildScript = ['bash ',buildDir,' ',currDateTime,' ',configFile,' ',logFile];
            
            BashCmd = sprintf('cd %s; %s ',...
                GitTargetDir,...
                GitBuildScript);
        end
        
        function pythonApp = getpythonApp(~)
            
            pythonApp='python';
        end%End of getpythonApp function
        
        function addDebugStatementsInSimulator(~, ~)
            % Do not add debug statements in Simulator module in Linux
        end
        
        function verifyIfError(~,workflowObject)
            buildError = codertarget.pixhawk.hwsetup.HardwareInterface.verifyIfErrorInBuild(workflowObject);
            if buildError
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:BuildPX4Firmware_Fail_Linux_Exception');
            end
        end
        
        function px4setup = getPX4FirmwareSetUpObj(obj, workflowObject) %#ok<INUSL>
            px4setup = px4.internal.fwsetup.PX4FirmwareSetup.getInstance(workflowObject.Px4_Cmake_Config,...
                workflowObject.Px4_Base_Dir);
        end
        
        
        function UploadCrazyflieBootloader(~,~)
            bootloader_path = fullfile(matlab.internal.get3pInstallLocation('crazyflie_bootloader.instrset'),'px4_crazyflie_bootloader-master', 'crazyflie_bootloader_binary.dfu');
            cmdStr = strcat('dfu-util -d 0483:df11 -a 0 -D ', bootloader_path); % Upload command
            sudoShell = matlabshared.internal.FwUpdateHelper; % This required to request a sudo permission to upload the bootloader
            sudoShell.init();
            [~ , out] = sudoShell.exec(cmdStr); % Run the command to upload the bootloader
            if ~contains (out ,'Download done.')
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DFU_upload_failed');
            end
            
            bootloader_path = fullfile(matlab.internal.get3pInstallLocation('crazyflie_bootloader.instrset'),'px4_crazyflie_bootloader-master', 'crazyflie_erase.dfu');
            cmdStr = strcat('dfu-util -d 0483:df11 -a 0 -D ', bootloader_path); % Upload command
            sudoShell = matlabshared.internal.FwUpdateHelper; % This required to request a sudo permission to upload the bootloader
            sudoShell.init();
            [~ , out] = sudoShell.exec(cmdStr); % Run the command to upload the bootloader
            if ~contains (out ,'Download done.')
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DFU_upload_failed');
            end
        end %End of UploadCrazyflieBootloader
        
        function PreviousScreen = getPreviousScreenValidate_DFU_utils(~)
            PreviousScreen ='codertarget.pixhawk.hwsetup.DownloadCrazyflieBootloaderUtility_linux';
        end %End of getPreviousScreenValidate_DFU_utils
        
        function PreviousScreen = getPreviousScreenValidatePX4(~)
            PreviousScreen = 'codertarget.pixhawk.hwsetup.DownloadPX4';
        end%End of getPreviousScreenValidatePX4
        
        function PreviousScreen = getPreviousScreenSetupPX4Toolchain(~)
            %In Linux, for PX4 Firmware v1.10.2, DownloadPX4 is the first screen.
            % SetupPX4Toolchain is called after ValidatePX4
            PreviousScreen = 'codertarget.pixhawk.hwsetup.ValidatePX4';
        end
        
        function NextScreen = getNextScreenSelectCMAKE(obj , workflow)
            if isequal(workflow.BoardName, message('px4:hwinfo:Crazyflie2_0').getString)
                NextScreen = 'codertarget.pixhawk.hwsetup.DownloadCrazyflieBootloaderUtility_linux';
            elseif strcmp(obj.SimulinkAlgorithm, message('px4:hwsetup:SelectAlgorithm_PathFollower').getString)  && ...
                    ~strcmp(workflow.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                NextScreen = 'codertarget.pixhawk.hwsetup.SelectAirframeInQGC';
            else
                NextScreen = 'codertarget.pixhawk.hwsetup.BuildPX4FirmwareCommon';
            end
        end%End of getNextScreenSelectCMAKE function
        
        function nextScreen = getNextScreenValidatePX4(obj, workflowObject)
            obj.isToolchainInstalled(workflowObject);
            if strcmpi(workflowObject.ToolchainInstalled,"NotInstalled")
                %If toolchain is not installed, user is directed to
                %SetupPX4Toolchain to setup the PX4 Toolchain
                nextScreen = 'codertarget.pixhawk.hwsetup.SetupPX4Toolchain';
            else
                nextScreen = 'codertarget.pixhawk.hwsetup.SelectAlgorithm';
            end
        end
        
        function PreviousScreen = getPreviousScreenConnectSDCard(~)
            PreviousScreen = 'codertarget.pixhawk.hwsetup.BuildPX4FirmwareCommon';
        end%End of getPreviousScreenConnectSDCard function
        
        function PreviousScreen = getNextScreenDownloadCrazyflieBootloaderUtility(~)
            PreviousScreen = 'codertarget.pixhawk.hwsetup.DownloadCrazyflieBootloaderUtility_linux';
        end%End of getNextScreenDownloadCrazyflieBootloaderUtility function
        
        function Validate_DFU_util(~,~,~)
            [status, out] = system('dpkg --status dfu-util|grep ''^Status:'''); % Check if the dfu-util is properly installed
            dfu_install_status = '';
            if status == 0
                dfu_install_status = regexp(out,'Status: install ok installed','match'); % Check if this string is found in the result
            end
            
            if isempty(dfu_install_status) % Throw error if the string is not found
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:dfu_util_linux');
            end
            
        end% End of Validate_DFU_util method
        
    end
    
    methods(Static)
        
        function Firmware_Image = getPX4FirmwareImage(workflowObject)
            if strcmp(workflowObject.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                
                Firmware_Image = fullfile(workflowObject.Px4_Base_Dir,...
                    'Firmware', 'build',workflowObject.Px4_Cmake_Config, 'bin','px4');
            else
                Firmware_Image = fullfile(workflowObject.Px4_Base_Dir,...
                    'Firmware', 'build',workflowObject.Px4_Cmake_Config,...
                    [workflowObject.Px4_Cmake_Config,'.px4']);
            end
            
            if ~isfile(Firmware_Image)
                Firmware_Image=[];
            end
        end%End of getPX4FirmwareImage method
        
        function Title = getSetupPX4ToolchainTitle()
            Title = message('px4:hwsetup:SetupPX4Toolchain_Title_Linux').getString;
        end
        
        function  helpText = getSetupPX4ToolchainHelpText(~)
            helpText = message('px4:hwsetup:SetupPX4Toolchain_Linux_WhatConsider').getString;
        end%End of getSetupPX4ToolchainHelpText method
        
        function  helpText = getDownloadPX4HelpText()
            helpText = message('px4:hwsetup:DownValPX4_WhatConsider_1','computer','terminal').getString;
        end%End of getDownloadPX4HelpText method
        
        function  helpText = getSelectHardwarePX4HelpText()
            helpText = message('px4:hwsetup:SelectBoardWhatToConsider','the computer').getString;
        end%End of getSelectHardwarePX4HelpText method
        
        function errMsg = getNextScreenSetupPX4ToolchainErrorMsg()
            errMsg = message('px4:hwsetup:SetupPX4Toolchain_BashRestart','the computer').getString;
        end%End of getNextScreenSetupPX4ToolchainErrorMsg
        
        function out = getBuildErrorMsg()
            out = 'px4:hwsetup:BuildPX4Firmware_Error_log_Linux';
        end%End of getBuildErrorMsg
        
    end
end
