classdef WindowsHardwareModule < codertarget.pixhawk.hwsetup.HardwareInterface
    % WindowsHardwareModule - Class that covers all hardware specific
    % callbacks in Windows.
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    properties
        % Base Directory location of Python. Eg: C:\python27
        Python_Install_Dir
        
        %Variable to hold Cygwin directory in Windows
        CygwinDir
    end
    
    properties (Constant)
        DEFAULTCYGWININSTALLDIR = fullfile('C:','px4_cygwin');
    end
    
    properties
        TpPkg
        TokenName
    end
    
    methods
        
        function obj = WindowsHardwareModule(varargin)
            obj@codertarget.pixhawk.hwsetup.HardwareInterface();
            %Taking the Python install dir from
            %the 3p install location
            if isfolder(fullfile(matlab.internal.get3pInstallLocation('python27.instrset'),'python'))
                obj.Python_Install_Dir = fullfile(matlab.internal.get3pInstallLocation('python27.instrset'),'python');
            else
                %If the 3P has not gone through, set the default python
                %location as 'C:\Python27'
                obj.Python_Install_Dir = fullfile('C:','Python27');
            end
        end
        
        function FWLocation = getDefaultFWLocation(obj)
            FWLocation = codertarget.pixhawk.internal.getPX4BaseDir;
            if isempty(FWLocation)
                cygwinFWfolder = fullfile(obj.CygwinDir,'home');
                if isfolder(cygwinFWfolder)
                    FWLocation = cygwinFWfolder;
                end
            end
        end%End of getDefaultFWLocation function
        
        function ver = getPX4FirmwareVersion(obj,workflowObject)
            
            %FWFolder - Firmware folder
            FWFolder = fullfile(workflowObject.Px4_Firmware_Dir);
            FWFolder = codertarget.pixhawk.hwsetup.WindowsHardwareModule.convertWin2CygwinPath(FWFolder);
            [st,verMsg] = system([fullfile(obj.CygwinDir,'run-console_px4_fw_ver.bat'),' ','"',FWFolder,'"']);
            
            verMsgArray = splitlines(strip(verMsg));
            % In some PC, it has been that Cygwin bash shell
            % throws random warnings on launch which cause this
            % command to get messed up. Assumption is that the
            % the last value in the result is the desired result
            ver = verMsgArray{end};
            if st
                error(message('px4:hwsetup:ValidatePX4_FWVerError',verMsg).getString);
            end
        end%End of getPX4FirmwareVersion method
        
        function ver = getCygwinVersion(~, userCygwinDir)
            
            %CygwinFolder - PX4 Cygwin
            CygwinFolder = userCygwinDir;
            CygwinFolder = codertarget.pixhawk.hwsetup.WindowsHardwareModule.convertWin2CygwinPath(CygwinFolder);
            [st,verMsg] = system([fullfile(userCygwinDir,'run-console_px4_fw_ver.bat'),' ','"',CygwinFolder,'"']);
            
            verMsgArray = splitlines(strip(verMsg));
            % In some PC, it has been that Cygwin bash shell
            % throws random warnings on launch which cause this
            % command to get messed up. Assumption is that the
            % the last value in the result is the desired result
            ver = verMsgArray{end};
            if st
                error(message('px4:hwsetup:SetupCygwinToolchain_CygwinVerError',verMsg).getString);
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
            
            % Cygwin Installation directory
            obj.TpPkg(3) = obj.createThirdPartyStruct();
            obj.TpPkg(3).Name = 'Cygwin';
            obj.TpPkg(3).RootDir = obj.CygwinDir;
            obj.TokenName{3} = 'CYGWINROOTDIR';
            
            % Python 3 Installation directory
            obj.TpPkg(4) = obj.createThirdPartyStruct();
            obj.TpPkg(4).Name = 'Python 2';
            obj.TpPkg(4).RootDir = obj.Python_Install_Dir;
            obj.TokenName{4} = 'PYTHONROOTDIR';
            
        end%End of updateTpPkg method
        
        function BuildCmd = getBuildCommand(obj,TargetDir,currDateTime,configFile,logFile)
            
            codertarget.pixhawk.hwsetup.HardwareInterface.verifyIfLogfilePresent(logFile);
            %Get the parent folder of TargetDir
            idcs   = strfind(TargetDir,filesep);
            TargetDir = TargetDir(1:idcs(end)-1);
            
            logFile = obj.convertWin2CygwinPath(logFile);
            BuildCmd = sprintf('%s',[fullfile(obj.CygwinDir,'run-console_Simulink_screen.bat'),...
                ' ',obj.convertWin2CygwinPath(TargetDir),' ',configFile,' ',...
                logFile,' ',currDateTime]);
        end%End of getBuildCommand function
        
        function pythonApp = getpythonApp(obj)
            %The Python install directory from 3P
            %install location or the location that user has pointed from
            %the screen.
            PythonRootDir = obj.Python_Install_Dir;
            
            %Return with appropriate error message when python not found
            pythonApp = fullfile(PythonRootDir,'python.exe');
            if ~isfile(pythonApp)
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:TestConn_PythonNotFound');
            end
            
        end%End of getpythonApp function
        
        function verifyIfError(~,workflowObject)
            buildError = codertarget.pixhawk.hwsetup.HardwareInterface.verifyIfErrorInBuild(workflowObject);
            if buildError
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:BuildPX4Firmware_Build_Error');
            end
        end
        
        function addDebugStatementsInSimulator(~, workflowObject)
            
            fullFileName = fullfile(workflowObject.Px4_Base_Dir,'Firmware','src', 'modules', 'simulator', 'simulator_mavlink.cpp');
            if ~isfile(fullFileName)
                px4.internal.util.CommonUtility.localizedError('simulator_mavlink not found');
            end
            backupFileName = [fullFileName,'.original'];
            if ~isfile(backupFileName)
                % No backup- probably first time
                %Take a back-up of the original cmake for the first time
                copyfile(fullFileName,backupFileName, 'f');
            else
                % Backup which is original is present; use that and modify
                if isfile(fullFileName)
                    delete(fullFileName);
                end
                copyfile(backupFileName, fullFileName, 'f')
            end
            
            fileID = fopen(fullFileName);
            % Store the entire contents of the simulator_mavlink.cpp File in file_cell_array
            sim_mavlink_cell_array = textscan( fileID, '%s', 'Delimiter','\n','whitespace', '', 'CollectOutput',true );
            fclose(fileID);
            sim_mavlink_cell_array = sim_mavlink_cell_array{1};
            indexToFind1 = find(contains(sim_mavlink_cell_array,'// Wait for up to 100ms for data'), 1);            
            indexToFind2 = find(contains(sim_mavlink_cell_array,'fds[0].revents & POLLIN'), 1);
            
            custom_sleep_code = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir, 'lib', 'Customize_Setup', 'simulator_modification', 'custom_sleep.txt');
            newfileID = fopen(custom_sleep_code);
            % Store the entire contents of the simulator_mavlink.cpp File in file_cell_array
            custom_sleep_cell_array = textscan( newfileID, '%s', 'Delimiter','\n','whitespace', '', 'CollectOutput',true );
            fclose(newfileID);
            custom_sleep_cell_array = custom_sleep_cell_array{1};
            
            % Add till polling code comment
            hs = StringWriter;
            for j=1:indexToFind1
                hs.addcr(sim_mavlink_cell_array{j});
            end
            
            % Add sleep code to replace polling
            for j=1:length(custom_sleep_cell_array)
                hs.addcr(custom_sleep_cell_array{j});
            end
            
            % Add code till check for Poll and skip adding if check
            for j = indexToFind1+2:indexToFind2-1
                hs.addcr(sim_mavlink_cell_array{j});
            end
            
            % Just add a opening brace instead of if condition
            hs.addcr('		{');
            
            % Add the rest of the code
            for j = indexToFind2+1:length(sim_mavlink_cell_array)
                hs.addcr(sim_mavlink_cell_array{j});
            end
            % Touch the file to change timestamp and trigger build
            hs.addcr('//This file was modified ');
            
            hs.write(fullFileName);
        end        
        
        function px4setup = getPX4FirmwareSetUpObj(obj, workflowObject)
            px4setup = px4.internal.fwsetup.PX4FirmwareSetup.getInstance(workflowObject.Px4_Cmake_Config,...
                workflowObject.Px4_Base_Dir,obj.CygwinDir);
        end
        
        function status = verifyUpload(~)
            cmd = ['wmic process where' ' "' 'name like ' '''%dfu%''' '"' ' get processid,commandline']; %Get all the processes with the name lie "dfu"
            [~, out] = system(cmd); %Run the command to get the dfu process running
            status = 1;
            
            if ~contains(out, 'No Instance')
                split = strsplit (out,' ');
                pid = split{length(split) - 1};
                cmd = ['taskkill /F /PID ' pid]; % Command to kill the terminal used to upload the bootloader
                [~, ~] = system(cmd); % Run the command to kill the process
                status = -1;
            end
            
            cmd = ['wmic process where' ' "' 'name like ' '''%cmd%''' '"' ' get processid,commandline']; % Get all the cmd processes
            [~, out] = system(cmd);
            
            if contains(out, 'crazy')
                split = strsplit (out,'\n');
                res = contains(split,'crazy'); % Find the process that contains the "bootloader" in its text
                str = split{res};
                split = strsplit (str,' ');
                pid = split{length(split) - 1}; % Ge the PID of the process
                
                cmd = ['taskkill /F /PID ' pid]; % Kill the process
                [~, ~] = system(cmd);
            end
        end
        
        
        function UploadCrazyflieBootloader(obj, WorkflowObj)
            dFuSeExe = fullfile(WorkflowObj.STM32_DFU_dir, 'DfuSeCommand.exe'); % Get the executable
            bootloader_path = fullfile(matlab.internal.get3pInstallLocation('crazyflie_bootloader.instrset'),'px4_crazyflie_bootloader-master', 'crazyflie_bootloader_binary.dfu');
            cmdStr = ['"', dFuSeExe, '"', '  -c --de 0 -d --fn ', bootloader_path, '&'];  % Upload command, will be run in a separate terminal
            [~ , ~] = system (cmdStr);  % Run the command to upload the bootloader
            pause(5); % Wait for 5 seconds to validate
            status = obj.verifyUpload(); % Validate the upload and close the newly opened terminals
            if status == -1
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DFU_upload_failed');
            end
            
            bootloader_path = fullfile(matlab.internal.get3pInstallLocation('crazyflie_bootloader.instrset'),'px4_crazyflie_bootloader-master', 'crazyflie_erase.dfu');
            cmdStr = ['"', dFuSeExe, '"', '  -c --de 0 -d --fn ', bootloader_path, '&'];  % Upload command, will be run in a separate terminal
            [~ , ~] = system (cmdStr);  % Run the command to upload the bootloader
            pause(5); % Wait for 5 seconds to validate
            status = obj.verifyUpload(); % Validate the upload and close the newly opened terminals
            if status == -1
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DFU_upload_failed');
            end
        end
        
        function PreviousScreen = getPreviousScreenValidate_DFU_utils(~)
            PreviousScreen ='codertarget.pixhawk.hwsetup.DownloadCrazyflieBootloaderUtility_win';
        end
        
        function NextScreen = getNextScreenSelectCMAKE(obj, workflow)
            if isequal(workflow.BoardName, message('px4:hwinfo:Crazyflie2_0').getString)
                NextScreen = 'codertarget.pixhawk.hwsetup.DownloadCrazyflieBootloaderUtility_win';
            elseif strcmp(obj.SimulinkAlgorithm, message('px4:hwsetup:SelectAlgorithm_PathFollower').getString) && ...
                    ~strcmp(workflow.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                NextScreen = 'codertarget.pixhawk.hwsetup.SelectAirframeInQGC';
            else
                NextScreen = 'codertarget.pixhawk.hwsetup.BuildPX4FirmwareCommon';
                
            end
        end%End of getNextScreenSelectCMAKE function
        
        function nextScreen = getNextScreenValidatePX4(~, ~)
            nextScreen = 'codertarget.pixhawk.hwsetup.SelectAlgorithm';
        end
        
        function NextScreen = getNextScreenDownloadCrazyflieBootloaderUtility(~)
            if ispc
                NextScreen = 'codertarget.pixhawk.hwsetup.DownloadCrazyflieBootloaderUtility_win';
            elseif isunix
                NextScreen = 'codertarget.pixhawk.hwsetup.DownloadCrazyflieBootloaderUtility_linux';
            end
        end %End of getNextScreenDownloadCrazyflieBootloaderUtility
        
        function PreviousScreen = getPreviousScreenConnectSDCard(~)
            PreviousScreen = 'codertarget.pixhawk.hwsetup.BuildPX4FirmwareCommon';
        end%End of getPreviousScreenConnectSDCard function
        
        function PreviousScreen = getPreviousScreenValidatePX4(~)
            PreviousScreen = 'codertarget.pixhawk.hwsetup.SetupCygwinToolchain';
        end%End of getPreviousScreenValidatePX4
        
        function Validate_DFU_util(~, worflowObj, autoValidate)
            
            DFU_dir = worflowObj.STM32_DFU_dir;
            if any(regexp(DFU_dir,'[!@#$%^&*]')) % Check for any invalid characters int the folder path
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:FWFolderNameNotSupported');
            end
            
            if autoValidate == 1
                try
                    contents = dir(DFU_dir); %get the contents of the folder provided
                    index = contains({contents.name}, 'DfuSe'); %Check if the DfuSe folder exists DfuSeCommand.exe is present
                    newDir =  contents(index).name; % Get the directory name.
                    DFU_dir = fullfile(DFU_dir, newDir, 'Bin'); % Get the full path of the new folder where
                    worflowObj.STM32_DFU_dir = DFU_dir;
                catch
                    %do nothing
                end
            end
            
            if exist(DFU_dir,'dir')
                if ~exist(fullfile(DFU_dir,'DfuSeCommand.exe'),'File') % Verify the command line exe exists in the entered path
                    px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DFU_not_found');
                end
            else
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DFU_not_found');
            end
            
        end% End of Validate_DFU_util method
    end
    
    methods(Static)
        function Firmware_Image = getPX4FirmwareImage(workflowObject)
            if strcmp(workflowObject.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                Firmware_Image = fullfile(workflowObject.Px4_Base_Dir,...
                    'Firmware', 'build',workflowObject.Px4_Cmake_Config, 'bin', 'px4.exe');
            else
                Firmware_Image = fullfile(workflowObject.Px4_Base_Dir,...
                    'Firmware', 'build', workflowObject.Px4_Cmake_Config,...
                    [workflowObject.Px4_Cmake_Config,'.px4']);
            end
            
            if ~isfile(Firmware_Image)
                Firmware_Image=[];
            end
        end%End of getPX4FirmwareImage method
        
        function CygwinPath = convertWin2CygwinPath(WinPath)
            %converting the windows path to Cygwin path
            WinPath = replace(WinPath,'\','/');
            WinPath(1)=lower(WinPath(1));
            DrvLetter = WinPath(1);
            CygwinPath = replace( (WinPath),[DrvLetter,':/'],['/cygdrive/',DrvLetter,'/']);
            %Replace any 'spaces' in path with '\ '
            %             CygwinPath = strrep(CygwinPath,' ','\ ');
        end%End of convertWin2CygwinPath method
        
        function Title = getSetupPX4ToolchainTitle()
            Title = message('px4:hwsetup:SetupPX4Toolchain_Title').getString;
        end
        
        function cygwinCheckout(cygwinFolder,FWFolder)
            %cygwinFolder - Cygwin installation folder
            %FWFolder - Firmware folder
            FWFolder = codertarget.pixhawk.hwsetup.WindowsHardwareModule.convertWin2CygwinPath(FWFolder);
            [st,cmd] = system([fullfile(cygwinFolder,'run-console_px4_checkout.bat'),...
                ' ','"',FWFolder,'"']); %#ok<ASGLU>
        end%End of cygwinCheckout function
        
        function  helpText = getSelectHardwarePX4HelpText()
            helpText = message('px4:hwsetup:SelectBoardWhatToConsider','PC').getString;
        end%End of getSelectHardwarePX4HelpText method
        
        function out = getBuildErrorMsg()
            out = 'px4:hwsetup:BuildPX4Firmware_Error_log';
        end%End of getBuildErrorMsg
        
    end
end
