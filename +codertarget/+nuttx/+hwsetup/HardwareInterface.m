classdef HardwareInterface < handle
    % HardwareInterface - Class that covers all hardware specific
    % callbacks.
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    properties
        ReqTpPkg
        toolInfoHandle
        ToolName = 'PX4 Tools'
        TargetName = 'px4'
    end
    
    properties
        %algorithm in Simulink
        SimulinkAlgorithm
    end
    
    properties (Abstract=true)
        TpPkg
        TokenName
    end
    
    methods
        
        function ThirdPartyToolsRegistration(obj, workflowObject)
            targetFolder = codertarget.pixhawk.internal.getSpPkgRootDir();
            fileName = codertarget.target.getThirdPartyToolsRegistrationFileName(targetFolder);
            try
                obj.toolInfoHandle = codertarget.thirdpartytools.ThirdPartyToolInfo(fileName, false);
            catch me %#ok<NASGU>
                obj.toolInfoHandle = codertarget.thirdpartytools.ThirdPartyToolInfo();
                obj.toolInfoHandle.setDefinitionFileName(fileName);
            end
            
            obj.toolInfoHandle.setName(obj.ToolName);
            obj.toolInfoHandle.setTargetName(obj.TargetName);
            
            obj.updateTpPkg(workflowObject);
            
            for i = 1:length(obj.TpPkg)
                if isempty(obj.TpPkg(i).RootDir)
                    for j = 1:numel(obj.toolInfoHandle.ThirdPartyTools)
                        if isequal(obj.TpPkg(i).Name, obj.toolInfoHandle.ThirdPartyTools{j}{1}.ToolName)
                            obj.TpPkg(i).RootDir = obj.toolInfoHandle.ThirdPartyTools{j}{1}.RootFolder;
                        end
                    end
                end
            end
            
        end
        
        function registerTPTOkens(obj)
            
            % Add PX4 Firmware
            obj.toolInfoHandle.addTool('ToolName', obj.TpPkg(1).Name, ...
                'Category', 'other', ...
                'TokenName', 'PX4FIRMWAREROOTDIR', ...
                'RootFolder', obj.TpPkg(1).RootDir);
            
            % Add Cmake Config
            if length(obj.TpPkg)>=2
                obj.toolInfoHandle.addTool('ToolName', obj.TpPkg(2).Name, ...
                    'Category', 'other', ...
                    'TokenName', 'CMAKEMAKECONFIG', ...
                    'RootFolder', obj.TpPkg(2).RootDir);
            end
            
            % Add Cygwin
            if length(obj.TpPkg)>=3
                obj.toolInfoHandle.addTool('ToolName', obj.TpPkg(3).Name, ...
                    'Category', 'other', ...
                    'TokenName', 'CYGWINROOTDIR', ...
                    'RootFolder', obj.TpPkg(3).RootDir);
            end
            
            % Add Python 2
            if length(obj.TpPkg)>=4
                obj.toolInfoHandle.addTool('ToolName', obj.TpPkg(4).Name, ...
                    'Category', 'other', ...
                    'TokenName', 'PYTHONROOTDIR', ...
                    'RootFolder', obj.TpPkg(4).RootDir);
            end
            
            fileName = obj.toolInfoHandle.DefinitionFileName;
            [status, attrib] = fileattrib(fileName);
            if status && ~attrib.UserWrite
                [status, message, messageid] = fileattrib(fileName, '+w');
                if ~status
                    error(messageid, [message strrep(fileName, '\', '/')]);
                end
            end
            % Register toolinfo
            obj.toolInfoHandle.register();
        end
        
        function outStruct = createThirdPartyStruct(~)
            outStruct = struct('FileName', '', 'DestDir', '', 'Installer', '', ...
                'Archive', '', 'Name', '', 'Version', '1.0', 'Url', '', 'DownloadUrl', '', ...
                'LicenseUrl', '', 'DownloadDir', '', 'InstallDir', '', 'IsInstalled', 0, ...
                'IsDownloaded', 0, 'RootDir', '');
        end
        
        function PX4FirmwareBuild(obj,workflowObject,TargetDir,currDateTime,varargin)
            
            if isempty(varargin) || isempty(varargin{1})
                configFile = workflowObject.Px4_Cmake_Config;
            else
                %when custom config option is chosen by the user.
                configFile = varargin{1};
            end
            
            BashCmd = obj.getBuildCommand(TargetDir,currDateTime,configFile,workflowObject.LOGFILE);
            [status,~] = system(BashCmd,'-echo');
            
            if status
                errMsg = obj.getBuildErrorMsg();
                px4.internal.util.CommonUtility.localizedError(errMsg);
            else
                obj.verifyIfError(workflowObject);
            end
        end
        
        function PX4IOFirmwareBuild(obj,workflowObject,TargetDir,currDateTime,varargin)
            %This function will build Connected I/O executables
            px4IOServerDir = px4.internal.ConnectedIO.getConnectedIOTempDir(workflowObject.BoardName);
            if isempty(varargin) || isempty(varargin{1})
                configFile = workflowObject.Px4_Cmake_Config; 
            else
                %when custom config option is chosen by the user.
                configFile = varargin{1};
            end

            BashCmd = obj.getBuildCommand(TargetDir,currDateTime,configFile,workflowObject.LOGFILE);
            [status,~] = system(BashCmd,'-echo');

            if status
                errMsg = obj.getBuildErrorMsg();
                px4.internal.util.CommonUtility.localizedError(errMsg);
            else
                obj.verifyIfError(workflowObject);
            end
            
            %copy executable to temp dir
            px4FirmwareBuildDir = fullfile(workflowObject.Px4_Firmware_Dir,'build',workflowObject.Px4_Cmake_Config);
            %create the Connected IO temp folder
            if ~exist(px4IOServerDir, 'dir')
                mkdir(px4IOServerDir); 
            end
            if strcmp(workflowObject.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                % for Host Target entire bin folder need to be copied
               copyfile(fullfile(px4FirmwareBuildDir, 'bin'), px4IOServerDir, 'f');
            else
               px4BinName = [workflowObject.Px4_Cmake_Config,'.px4'];
               copyfile(fullfile(px4FirmwareBuildDir,px4BinName), px4IOServerDir, 'f');
            end
        end
        
        function PX4FirmwareValidate(obj,workflowObject)
            
            workflowObject.Px4_Firmware_Dir = fullfile( workflowObject.Px4_Base_Dir,...
                'Firmware');
            workflowObject.Px4_Simulink_Module_Dir = fullfile(workflowObject.Px4_Firmware_Dir,...
                'src','modules','px4_simulink_app');
            
            if any(regexp(workflowObject.Px4_Base_Dir,'[!@#$%^&*() ]'))
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:FWFolderNameNotSupported');
            end
            if exist(workflowObject.Px4_Firmware_Dir,'dir')
                PX4_ver = obj.getPX4FirmwareVersion(workflowObject);
                
                %Supported PX4 version tags v1.10.2. Error thrown for any
                %other version/tag
                
                if isempty(PX4_ver)
                    px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DownValPX4_network_path_issue');
                else
                    if contains(PX4_ver,'v1.8.')
                        % throw an error mentioning 1.8 support deprecation
                        px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DownValPX4_v180_Firmware',PX4_ver,workflowObject.GITTAG);
                    elseif  ~strcmpi(strip(PX4_ver),workflowObject.GITTAG)
                        %Throw an warning if the Firmware version is anything
                        %other than v1.10.2
                        px4.internal.util.CommonUtility.localizedWarning('px4:hwsetup:DownValPX4_wrong_Firmware',PX4_ver,workflowObject.GITTAG);
                    end
                end
            else
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DownValPX4_Firmware_folder_notFound');
            end
            
        end% End of PX4FirmwareValidate method
        
        function validateCMake(~, workflowObject, cmakeName)
            workflowObject.Px4_Cmake_Config = erase(cmakeName,'.cmake');
            % The cmake name entered by the user is the configuration
            % target name which PX4 defines as VENDOR_MODEL_VARIANT.
            % Splitting the configuration name based on _ to isolate
            % vendor, model and variant
            folderNames = strsplit(cmakeName, '_');
            
            if numel(folderNames) ~= 3
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DownValPX4_cmakeFile_notFound',cmakeName);
            end
            workflowObject.CMakeVendor = folderNames{1};
            workflowObject.CMakeModel = folderNames{2};
            workflowObject.CMakeVariant = strcat(folderNames{3}, '.cmake');
            
            pathToVariant = fullfile(workflowObject.Px4_Base_Dir,'Firmware','boards', workflowObject.CMakeVendor, workflowObject.CMakeModel);
            
            if ~isfolder(pathToVariant)
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DownValPX4_cmakeFolder_notFound', workflowObject.CMakeVendor ,workflowObject.CMakeModel ,fullFileName);
            end
            
            cmakePath = fullfile(workflowObject.Px4_Base_Dir,'Firmware','boards', workflowObject.CMakeVendor, workflowObject.CMakeModel,  workflowObject.CMakeVariant);
            if ~isfile(cmakePath)
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DownValPX4_cmakeFile_notFound',cmakePath);
            end
            
        end% End of validateCMake method
        
        function modifyCmakeFile(~,workflowObject, cmakeConfig)
            
            filename = cmakeConfig;
            
            fullFileName = fullfile(workflowObject.Px4_Base_Dir,'Firmware','boards',workflowObject.CMakeVendor,workflowObject.CMakeModel, workflowObject.CMakeVariant);
            if ~isfile(fullFileName)
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DownValPX4_cmakeFile_notFound',fullFileName);
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
            % Store the entire contents of the CMAKE File in cmakefile_cell_array
            cmakefile_cell_array = textscan( fileID, '%s', 'Delimiter','\n','whitespace', '', 'CollectOutput',true );
            fclose(fileID);
            cmakefile_cell_array = cmakefile_cell_array{1};
            
            % Check if the CMAKE File has px4_simulink_app
            if isempty( find(contains(cmakefile_cell_array,'px4_simulink_app'), 1) )
                % Find the Line number where 'MODULES'
                % is in the CMAKE File and add the Simulink Module
                % below it.
                index = find(contains(cmakefile_cell_array,'MODULES'), 1);
                % Using the String Writer class created for writing
                % CMAKELists.txt
                hs = StringWriter;
                % Copy the lines from the original CMAKE file as it is
                % till the line containing 'set(config_module_list'
                for i=1:index
                    hs.addcr(cmakefile_cell_array{i});
                end
                
                % Add 'modules/px4_simulink_app' to the CMAKE File
                hs.addcr(sprintf('\t\t%s', '#'));
                hs.addcr(sprintf('\t\t%s','# PX4 Simulink App Module'));
                hs.addcr(sprintf('\t\t%s', '#'));
                hs.addcr(sprintf('\t\t%s', 'px4_simulink_app'));
                
                % Find the Line number where 'modules/fw_att_control'
                % and 'modules/fw_pos_control_11' is in the CMAKE File
                indexToComment1 = find(contains(cmakefile_cell_array,'fw_att_control'), 1);
                indexToComment2 = find(contains(cmakefile_cell_array,'fw_pos_control_l1'), 1);
                indexToComment3 = find(contains(cmakefile_cell_array,'mc_att_control'), 1);
                indexToComment4 = find(contains(cmakefile_cell_array,'mc_pos_control'), 1);
                indexToComment5 = find(contains(cmakefile_cell_array,'vtol_att_control'), 1);
                
                % Copy the lines from the original CMAKE file as it is
                % till the end
                for j=index+1:length(cmakefile_cell_array)
                    if contains(filename,'px4_fmu-v2')
                        %Comment the controller modules for
                        %building in px4_fmu-v2** file.
                        %If this is not done, the build fails with
                        %flash overflow issue
                        if isequal(j,indexToComment1)
                            hs.addcr(sprintf('\t\t%s','#fw_att_control'));
                        elseif isequal(j,indexToComment2)
                            hs.addcr(sprintf('\t\t%s', '#fw_pos_control_l1'));
                        elseif isequal(j,indexToComment3)
                            hs.addcr(sprintf('\t\t%s', '#mc_att_control'));
                        elseif isequal(j,indexToComment4)
                            hs.addcr(sprintf('\t\t%s', '#mc_pos_control'));
                        elseif isequal(j,indexToComment5)
                            hs.addcr(sprintf('\t\t%s', '#vtol_att_control'));
                        else
                            hs.addcr(cmakefile_cell_array{j});
                        end
                    elseif strcmp(filename, message('px4:hwinfo:Crazyflie2_0CmakeDefault').getString)
                        if isequal(j,indexToComment3)
                            hs.addcr(sprintf('\t\t%s', '#mc_att_control'));
                        elseif isequal(j,indexToComment4)
                            hs.addcr(sprintf('\t\t%s', '#mc_pos_control'));
                        else
                            hs.addcr(cmakefile_cell_array{j});
                        end
                    else
                        hs.addcr(cmakefile_cell_array{j});
                    end
                end
                
                hs.write(fullFileName);
            end
        end% End of function modifyCmakeFile method
        
        function modifyStartupScript(obj, workflowObject, moduleToDisable)
            obj.addSimulinkApplicationIfNeeded(workflowObject, moduleToDisable);
        end
        
        function revertStartUpScriptIfNeeded(~, workflowObject)
            % revert the rCS script if px4_simulink_app was added for Path
            % Follower scenario
            rCSFileName = fullfile(workflowObject.Px4_Base_Dir,'Firmware','ROMFS','px4fmu_common','init.d','rcS');
            if ~isfile(rCSFileName)
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DownValPX4_rcS_notFound');
            end
            
            backupFileName = [rCSFileName,'.original'];
            if ~isfile(backupFileName)
                % No backup- probably first time and hence nothing to do;
                % the original file is good
                return;
            else
                % Backup which is original is present; check if it contains
                % the px4_simulink_app
                fileID = fopen(rCSFileName);
                % Store the entire contents of the CMAKE File in cmakefile_cell_array
                cmakefile_cell_array = textscan( fileID, '%s', 'Delimiter','\n', 'whitespace', '', 'CollectOutput',true );
                fclose(fileID);
                cmakefile_cell_array = cmakefile_cell_array{1};
                % If contains 'px4_simulink_app', delete it and replace it
                % with the backup (original file)
                if ~isempty( find(contains(cmakefile_cell_array,'px4_simulink_app start'), 1) )
                    delete(rCSFileName);
                    copyfile(backupFileName, rCSFileName, 'f');
                end
            end
        end
        
        function addSimulinkApplicationIfNeeded(~, workflowObject, moduleToDisable)
            rCSFileName = fullfile(workflowObject.Px4_Base_Dir,'Firmware','ROMFS','px4fmu_common','init.d','rcS');
            if ~isfile(rCSFileName)
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DownValPX4_rcS_notFound');
            end
            
            backupFileName = [rCSFileName,'.original'];
            if ~isfile(backupFileName)
                % No backup- probably first time
                %Take a back-up of the original rCS for the first time
                copyfile(rCSFileName,backupFileName, 'f');
            else
                % Backup which is original is present; use that and modify
                if isfile(rCSFileName)
                    delete(rCSFileName);
                end
                copyfile(backupFileName, rCSFileName, 'f')
            end
            
            fileID = fopen(rCSFileName);
            % Store the entire contents of the rCS File in rCSfile_cell_array
            rCSfile_cell_array = textscan( fileID, '%s', 'Delimiter','\n', 'whitespace', '', 'CollectOutput',true );
            fclose(fileID);
            rCSfile_cell_array = rCSfile_cell_array{1};
            
            % Check if the rCS File has px4_simulink_app
            if isempty( find(contains(rCSfile_cell_array,'px4_simulink_app start'), 1) )
                
                % Using the String Writer class created for writing
                % rCS
                hs = StringWriter;
                
                % Disable the navigator modules in rcS script
                indexToComment = find(contains(rCSfile_cell_array,moduleToDisable), 1);
                
                % Copy the lines from the original rCS file as it is
                % till the end
                for j=1:length(rCSfile_cell_array)
                    if isequal(j,indexToComment)
                        hs.addcr('#navigator start');
                    else
                        hs.addcr(rCSfile_cell_array{j});
                    end
                end
                
                % Add 'px4_simulink_app' to the rCS File
                hs.addcr('#');
                hs.addcr('# PX4 Simulink App Module');
                hs.addcr('#');
                hs.addcr('px4_simulink_app start');
                
                hs.write(rCSFileName);
            end
            
        end
        
        function customizeSITLLaunchScript(~,workflowObject)
            % customize the sitl launch shell script (sitl_run.sh) to start
            % the sitl without lock step option and save it as new shell
            % script (sitl_run_no_lockstep.sh)
            launchScriptName = fullfile(workflowObject.Px4_Base_Dir,'Firmware','Tools','sitl_run.sh');
            newLaunchScriptName = fullfile(workflowObject.Px4_Base_Dir,'Firmware','Tools','sitl_run_no_lockstep.sh');
            % check if already customized
            if ~isfile(newLaunchScriptName)
                % read contents of 'sitl_run.sh'
                fid = fopen(launchScriptName,'r');
                fileContents =fscanf(fid,'%c');
                fclose(fid);
                % remove the '-l' option to start sitl without lock step
                newFileContents = strrep(fileContents,'jmavsim_run.sh -r 250 -l','jmavsim_run.sh -r 250');
                % write the modified contents to 'sitl_run_no_lockstep.sh'
                fid = fopen(newLaunchScriptName,'w');
                fwrite(fid,newFileContents);
                fclose(fid);
                if isunix
                    %add executable permission for sitl_run_no_lockstep.sh
                    %in Linux
                    system(['chmod a+x ',newLaunchScriptName]);
                end
            end
        end
        
        function addSimulinkFolder(~,workflowObject)
            
            if  exist(workflowObject.Px4_Simulink_Module_Dir,'dir') %~isempty(ls(px4app_path))
                %delete the existing contents of the folder
                delete([workflowObject.Px4_Simulink_Module_Dir,filesep,'*']);
            end
            folders = {'px4_simulink_app','src','include'};
            
            for kk = 1:length(folders)
                
                switch folders{kk}
                    case 'px4_simulink_app'
                        % srcPath is present in the Support package directory
                        % which contains the folder to be copied
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'lib','Customize_Setup',folders{kk});
                    case 'src'
                        % srcPath is present in the Support package directory
                        % which contains the folder to be copied
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'src');
                    otherwise
                        % copying the .c files from 'src' directory
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'include');
                end
                
                % dstPath: Ex-> C:\px4\Firmware\src\modules\px4_simulink_app
                dstPath = workflowObject.Px4_Simulink_Module_Dir;
                
                if ~isfolder(dstPath)
                    %Uncomment below for Debugging
                    %                     disp([folders{kk},' folder does not exist. Creating directory and copying files.']);
                    mkdir(dstPath)
                end
                copyfile(srcPath, dstPath, 'f');
            end
        end %End of function addSimulinkFolder method
        
        function addIOSimulinkFolder(~,workflowObject)
            
            if  exist(workflowObject.Px4_Simulink_Module_Dir,'dir')
                %delete the existing contents of the folder
                delete([workflowObject.Px4_Simulink_Module_Dir,filesep,'*']);
            end
            folders = {'px4_simulink_app','px4src','px4include','connectedIOsrc','connectedIOinclude','svdinclude','IOServerinclude','IOServersrc'};
            
            for folderIdx = 1:length(folders)
                
                switch folders{folderIdx}
                    case 'px4_simulink_app'
                        % srcPath is present in the Support package directory
                        % which contains the folder to be copied
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'lib','Customize_Setup','px4_simulink_app_IO');
                    case 'px4src'
                        % srcPath is present in the Support package directory
                        % which contains the folder to be copied
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'src');
                    case 'px4include'
                        % copying the header files from 'include' directory
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'include');
                    case 'connectedIOsrc'
                        % copying the source files from Connected I/O 'src' directory
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'ConnectedIO','src');
                    case 'connectedIOinclude'
                        % copying the source files from Connected I/O 'include' directory
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'ConnectedIO','include');
                    case 'svdinclude'
                        % copying the header files from 'include' directory
                        srcPath = fullfile(matlabshared.svd.internal.getRootDir,...
                            'include');
                    case 'IOServerinclude'
                        % copying the source files from Connected I/O 'src' directory
                        srcPath = fullfile(matlabshared.ioclient.internal.getIOServerRootDir,...
                            'ioserver','inc');
                    case 'IOServersrc'
                        % copying the source files from Connected I/O 'include' directory
                        srcPath = fullfile(matlabshared.ioclient.internal.getIOServerRootDir,...
                            'ioserver','src');
                end
                
                % dstPath: Ex-> C:\px4\Firmware\src\modules\px4_simulink_app
                dstPath = workflowObject.Px4_Simulink_Module_Dir;
                if ~isfolder(dstPath)
                    mkdir(dstPath)
                end
                
                %copy other files to px4_simulink_app
                copyfile(srcPath, dstPath, 'f');
            end
        end %End of function addIOSimulinkFolder method
        
        function addSimulinkFolderForSITL(obj,workflowObject)
            
            if  exist(workflowObject.Px4_Simulink_Module_Dir,'dir') %~isempty(ls(px4app_path))
                %delete the existing contents of the folder
                delete([workflowObject.Px4_Simulink_Module_Dir,filesep,'*']);
            end
            folders = {'px4_simulink_app','src','include'};
            
            for kk = 1:length(folders)
                
                switch folders{kk}
                    case 'px4_simulink_app'
                        % srcPath is present in the Support package directory
                        % which contains the folder to be copied
                        switch obj.SimulinkAlgorithm
                            case message('px4:hwsetup:SelectAlgorithm_FlightController').getString
                                %If user wants to design Flight Controller in Simulink
                                srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                                    'lib','Customize_Setup','px4_simulink_app_SITL_FC');
                            case message('px4:hwsetup:SelectAlgorithm_PathFollower').getString
                                %If user wants to design Path Follower in Simulink
                                srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                                    'lib','Customize_Setup','px4_simulink_app_SITL');
                        end
                    case 'src'
                        % srcPath is present in the Support package directory
                        % which contains the folder to be copied
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'src');
                    otherwise
                        % copying the header files from 'include' directory
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'include');
                end
                
                % dstPath: Ex-> C:\px4\Firmware\src\modules\px4_simulink_app
                dstPath = workflowObject.Px4_Simulink_Module_Dir;
                
                if ~isfolder(dstPath)
                    mkdir(dstPath)
                end
                copyfile(srcPath, dstPath, 'f');
            end
        end %End of function addSimulinkFolderForSITL method
        
        function addIOSimulinkFolderForSITL(~,workflowObject)
            
            if  exist(workflowObject.Px4_Simulink_Module_Dir,'dir')
                %delete the existing contents of the folder
                delete([workflowObject.Px4_Simulink_Module_Dir,filesep,'*']);
            end
            folders = {'px4_simulink_app','px4src','px4include','connectedIOsrc','connectedIOinclude','svdinclude','IOServerinclude','IOServersrc'};
            
            for folderIdx = 1:length(folders)
                
                switch folders{folderIdx}
                    case 'px4_simulink_app'
                        % srcPath is present in the Support package directory
                        % which contains the folder to be copied
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'lib','Customize_Setup','px4_simulink_app_SITL_IO');
                    case 'px4src'
                        % srcPath is present in the Support package directory
                        % which contains the folder to be copied
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'src');
                    case 'px4include'
                        % copying the header files from 'include' directory
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'include');
                    case 'connectedIOsrc'
                        % copying the source files from Connected I/O 'src' directory
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'ConnectedIO','src');
                    case 'connectedIOinclude'
                        % copying the source files from Connected I/O 'include' directory
                        srcPath = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,...
                            'ConnectedIO','include');
                    case 'svdinclude'
                        % copying the header files from 'include' directory
                        srcPath = fullfile(matlabshared.svd.internal.getRootDir,...
                            'include');
                    case 'IOServerinclude'
                        % copying the source files from Connected I/O 'src' directory
                        srcPath = fullfile(matlabshared.ioclient.internal.getIOServerRootDir,...
                            'ioserver','inc');
                    case 'IOServersrc'
                        % copying the source files from Connected I/O 'include' directory
                        srcPath = fullfile(matlabshared.ioclient.internal.getIOServerRootDir,...
                            'ioserver','src');
                end
                
                % dstPath: Ex-> C:\px4\Firmware\src\modules\px4_simulink_app
                dstPath = workflowObject.Px4_Simulink_Module_Dir;
                if ~isfolder(dstPath)
                    mkdir(dstPath)
                end
                
                %copy other files to px4_simulink_app
                copyfile(srcPath, dstPath, 'f');
            end
        end %End of function addIOSimulinkFolderForSITL method
        
        function customizePX4Firmware(obj,workflowObject)
            if strcmp(workflowObject.BoardName, message('px4:hwinfo:Crazyflie2_0').getString) ...
				|| strcmp(workflowObject.BoardName, message('px4:hwinfo:CustomBoard').getString)
                % Connected IO not used for Test connection for Crazyflie 2.0 and Custom Board
                obj.addSimulinkFolder(workflowObject);
            else
                obj.addIOSimulinkFolder(workflowObject);
            end
            obj.modifyTestCmakeList(workflowObject);
            
        end% End of customizePX4Firmware method
        
        function customizePX4FirmwareForSITL(obj,workflowObject)
            
            obj.addSimulinkFolderForSITL(workflowObject);
            obj.modifyTestCmakeList(workflowObject);
            obj.addDebugStatementsInSimulator(workflowObject);
            obj.unpoisonExitFunction(workflowObject);
        end% End of customizePX4FirmwareForSITL method
        
        function customizePX4IOFirmwareForSITL(obj,workflowObject)
            
            obj.addIOSimulinkFolderForSITL(workflowObject);
            obj.modifyTestCmakeList(workflowObject);
            obj.customizeSITLLaunchScript(workflowObject);
        end% End of customizePX4IOFirmwareForSITL method
        
        function PX4FirmwareUpload(obj,workflowObject,COMPort)
            
            Firmware_Image = obj.getPX4FirmwareImage(workflowObject);
            if isempty(Firmware_Image)
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:FWImage_Not_Found');
            end
            
            %Upload script location is also specific to v1.10.2 version.
            %Could be different for other versions
            Upload_Script = fullfile(workflowObject.Px4_Base_Dir,'Firmware','Tools','px_uploader.py');
            
            pythonApp = obj.getpythonApp();
            
            Upload_Cmd = px4.internal.util.CommonUtility.getfirmwareUploadCmd(pythonApp,Upload_Script,COMPort,Firmware_Image);
            
            [status,result] = system(Upload_Cmd,'-echo');
            
            if status
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:TestConn_SystemError',result);
            end
        end
        
        function modifyTestCmakeList(obj,workflowObject)
            try
                %This function modifies the Test CMakelist by adding a
                %comment at the end. We have seen issues when the same
                %CMakeLists.txt is used in Cygwin toolchain without any
                %modification. This is a workaround for that.
                fullFileName = fullfile(workflowObject.Px4_Simulink_Module_Dir,'CMakeLists.txt');
                if ~isfile(fullFileName)
                    px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DownValPX4_cmakelist_notFound',fullFileName);
                end
                fileID = fopen(fullFileName);
                cmakefile_cell_array = textscan( fileID, '%s', 'Delimiter','\n', 'whitespace', '', 'CollectOutput',true );
                fclose(fileID);
                bkup_file = [fullFileName,'.original'];
                if isfile(bkup_file)
                    delete(bkup_file)
                end
                %Take a back-up of the original CMAKE File
                movefile(fullFileName,bkup_file)
                cmakefile_cell_array = cmakefile_cell_array{1};
                hs = StringWriter;
                
                % Copy the lines from the original CMAKE file as it is
                % till the end
                for j=1:length(cmakefile_cell_array)
                    hs.addcr(cmakefile_cell_array{j});
                end
                hs.addcr();
                hs.addcr(['## This cmakelist.txt file was generated on ',...
                    obj.getCurrentDateTime()]);
                
                hs.write(fullFileName);
            catch ME
                %Restore the cmakelist.txt in case there is an error before
                %the new cmakelist.txt is created.
                if ~isfile(fullFileName)
                    movefile(bkup_file,fullFileName)
                end
                error(ME.message);
            end
        end %End of modifyTestCmakeList function
        
        function NextScreen = getNextScreenSelectAlgorithm(~)
            NextScreen =  'codertarget.pixhawk.hwsetup.SelectCMAKEandHardware';
        end
        
        function NextScreen = getNextScreenBuildPX4Firmware(obj, workflowObject)
            % Flight Controller && Simulation : Test Connection (Host Target)
            % Flight Controller && Deployment : SD card
            % Path follower && Simulation : Test Connection (Host Target)
            % Path follower && Deployment : Test Connection
            switch obj.SimulinkAlgorithm
                case message('px4:hwsetup:SelectAlgorithm_FlightController').getString
                    %If user wants to design Flight Controller in Simulink
                    if strcmp(workflowObject.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                        NextScreen =  'codertarget.pixhawk.hwsetup.TestConnectionHostTarget';
                    elseif isequal(workflowObject.BoardName,message('px4:hwinfo:Crazyflie2_0').getString)
                        NextScreen =  'codertarget.pixhawk.hwsetup.TestConnection';
                    else
                        NextScreen =  'codertarget.pixhawk.hwsetup.ConnectSDCard';
                    end
                case message('px4:hwsetup:SelectAlgorithm_PathFollower').getString
                    %If user wants to design Path Follower in Simulink
                    if strcmp(workflowObject.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                        NextScreen =  'codertarget.pixhawk.hwsetup.TestConnectionHostTarget';
                    else
                        NextScreen =  'codertarget.pixhawk.hwsetup.TestConnection';
                    end
                otherwise
                    NextScreen = 'codertarget.pixhawk.hwsetup.ConnectSDCard';
            end
        end
        
        function PrevScreen = getPreviousScreenTestConnection(obj, workflowObject)
            switch obj.SimulinkAlgorithm
                case message('px4:hwsetup:SelectAlgorithm_FlightController').getString
                    %If user wants to design Flight Controller in Simulink
                    if strcmp(workflowObject.BoardName, message('px4:hwinfo:PX4HostTarget').getString) || ...
                            strcmp(workflowObject.BoardName,message('px4:hwinfo:Crazyflie2_0').getString)
                        PrevScreen =  'codertarget.pixhawk.hwsetup.BuildPX4FirmwareCommon';
                    else
                        PrevScreen =  'codertarget.pixhawk.hwsetup.ConnectSDCard';
                    end
                case message('px4:hwsetup:SelectAlgorithm_PathFollower').getString
                    %If user wants to design Path Follower in Simulink
                    PrevScreen =  'codertarget.pixhawk.hwsetup.BuildPX4FirmwareCommon';
                otherwise
                    PrevScreen = 'codertarget.pixhawk.hwsetup.ConnectSDCard';
            end
        end
        
        function out = getPreviousScreenBuildPX4Firmware(~, workflowObject)
            
            if isequal(workflowObject.BoardName,message('px4:hwinfo:Crazyflie2_0').getString)
                out = 'codertarget.pixhawk.hwsetup.UploadCrazyflieBootloader';
            else
                out = 'codertarget.pixhawk.hwsetup.SelectCMAKEandHardware';
            end
        end
        
    end%End of methods
    
    methods (Static)
        
        function dir = getImageDir(workflowObject, varargin)
            if isempty(varargin)
                dir = workflowObject.ResourcesDir;
            else
                dir = fullfile(workflowObject.ResourcesDir, varargin{1});
            end
        end
        
        function unpoisonExitFunction(workflowObject)
            % unpoisonExitFunction The 'exit' function is poisoned by PX4
            % Firmware for POSIX builds in the visibility.h file located at
            % Firmware\src\include\visibility.h. The function definition is 
            % poisoned as shown below. 
            % #pragma GCC poison exit
            % This prohibits use of the 'exit' function in our C++ and header 
            % files for posix build as using this function would cause compilation
            % failure for the files where 'exit' is used. Till
            % now we had control for our own files. However XCP files such
            % 'xcp_ext_work.c' also use the 'exit' function and it is beyond
            % our control. Hence modifying it on the firmware side to unpoison
            % the 'exit' function
            
            fullFileName = fullfile(workflowObject.Px4_Base_Dir,'Firmware','src', 'include', 'visibility.h');
            if ~isfile(fullFileName)
                px4.internal.util.CommonUtility.localizedError('visibility.h not found');
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
            % Store the entire contents of the CMAKE File in cmakefile_cell_array
            fileContents_cell_array = textscan( fileID, '%s', 'Delimiter','\n','whitespace', '', 'CollectOutput',true );
            fclose(fileID);
            fileContents_cell_array = fileContents_cell_array{1};
            
            indexToFind1 = find(contains(fileContents_cell_array,'#pragma GCC poison exit'), 1);
            hs = StringWriter;
            % Copy the lines from the original header file except for the
            % poison line
            for i=1:length(fileContents_cell_array)
                if ~isequal(indexToFind1, i)
                    hs.addcr(fileContents_cell_array{i});
                end
            end
            
            hs.write(fullFileName);
            
        end
        
        function buildError = verifyIfErrorInBuild(workflowObject)
            %This function is used to verify if Build is completed
            %successfully or not by parsing the log file. It looks for 'Error'
            
            %verifyIfLogfilePresent before using 'fopen' on logfile
            if codertarget.pixhawk.hwsetup.HardwareInterface.verifyIfLogfilePresent(workflowObject.LOGFILE)
                fileID = fopen(workflowObject.LOGFILE);
                logfile_cell_array = textscan( fileID, '%s', 'Delimiter','\n', 'CollectOutput',true );
                fclose(fileID);
                logfile_cell_array = logfile_cell_array{1};
                verifyTag = ['BUILDSTARTING_',workflowObject.BuildTimeStamp];
                index_top = find(contains(logfile_cell_array,verifyTag), 1);
                verifyTag = ['BUILDCOMPLETE_',workflowObject.BuildTimeStamp];
                index_bottom = find(contains(logfile_cell_array,verifyTag), 1);
                if any(contains(logfile_cell_array(index_top:index_bottom),{'Error','Stop'},'IgnoreCase',true))
                    buildError = true;
                else
                    buildError = false;
                end
            else
                buildError = false;
            end
        end
        
        function out = getInstance(workflowObj)
            
            if ispc
                out = codertarget.pixhawk.hwsetup.WindowsHardwareModule(workflowObj);
            elseif ismac
                out = codertarget.pixhawk.hwsetup.MACHardwareModule();
            else
                out = codertarget.pixhawk.hwsetup.LinuxHardwareModule(workflowObj);
            end
            
        end
        
        function currDateTime = getCurrentDateTime()
            currDateTime = datestr(datetime('now'));
            currDateTime = strrep(currDateTime,{' '},{'_'});
            currDateTime = strrep(currDateTime,{':'},{'-'});
            currDateTime = currDateTime{1};
        end%End of getCurrentDateTime method
        
        function out = verifyIfLogfilePresent(logfile)
            %If the log file is deleted by mistake, a new log file is
            %created. The function return tells the function caller, if the
            %log file had been deleted or not.
            if ~isfile(logfile)
                fid = fopen(logfile,'w');
                fprintf(fid, '%s \n', "MathWorks PX4 Log File");
                fclose(fid);
                out = false;
            else
                out = true;
            end
        end%End of verifyIfLog filePresent method
        
    end%End of static methods
    
    methods(Abstract)
        %         updatePlatformInfo(obj)
        PreviousScreen = getPreviousScreenValidatePX4(obj);
        FWLocation = getDefaultFWLocation(obj)
        ver = getPX4FirmwareVersion(obj,workflowObject,Px4_Firmware_Dir)
        updateTpPkg(obj,workflowObject)
        BashCmd = getBuildCommand(obj,TargetDir,currDateTime,configFile,logFile)
        verifyIfError(obj,workflowObject)
        out = getNextScreenSelectCMAKE(obj,workflow)
        out = getPreviousScreenConnectSDCard(obj)
        px4setup = getPX4FirmwareSetUpObj(workflowObject);
        UploadCrazyflieBootloader(obj,Workflow)
        PreviousScreen = getPreviousScreenValidate_DFU_utils(obj)
        nextScreen = getNextScreenValidatePX4(obj, workflowObject)
        addDebugStatementsInSimulator(obj, workflowObject);
    end
    
    methods(Abstract, Static)
        title = getSetupPX4ToolchainTitle()
        helpText = getSelectHardwarePX4HelpText()
        out = getBuildErrorMsg()
        pythonApp = getpythonApp()
        Firmware_Image = getPX4FirmwareImage(workflowObject);
    end
end
