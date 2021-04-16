classdef SetupCygwinToolchain < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    
    %   SetupCygwinToolchain - Screen provides the instructions to setup Cygwin
    %   Toolchain. This screen is present only in Windows.
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        
        %Description text for the screen
        ScreenDescription
        
        % ValidateEditText - Text box area to show install location that has
        % to be validated.
        ValidateEditText
        % BrowseButton - Button that on press opens a filesystem browser
        % for user to pick the correct install location.
        BrowseButton
        % ValidateCygwinButton - Button that Validates the Cygwin Toolchain Installation.
        ValidateCygwinButton
        % Status Table to show the status of validation
        StatusTable
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    properties (Constant)
        
        FILES = {'run-console_Simulink.bat', 'run-console_SimulinkBackGnd.bat', 'run-console_Simulink_screen.bat',...
            'run-console_px4_checkout.bat','run-console_px4_fw_ver.bat'};
        ERRORLEVELTEXT= {'@if errorlevel 1 goto error_exit','exit 0',':error_exit',...
            'echo PX4 Cygwin returned an error of %errorlevel%','exit 1'};
    end
    
    methods
        
        function obj = SetupCygwinToolchain(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})
            
            % Set the Title Text
            obj.Title.Text = message('px4:hwsetup:SetupCygwinToolchain_Title').getString;
            %Default position is [20 7 470 25], But increasing it to accommodate the lengthier title
            obj.Title.Position = [20 7 550 25];
            
            % Set Description Properties
            obj.ScreenDescription = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenDescription.Position = [20 200 430 180];
            obj.ScreenDescription.Text = message('px4:hwsetup:SetupCygwinToolchain_Description').getString;
            obj.ConfigurationInstructions.Visible = 'off';
            
            %Set ValidateEdit Properties
            obj.ValidateEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.ValidateEditText.ValueChangedFcn = @obj.editCallbackFcn;
            obj.ValidateEditText.Position = [20 200 300 20];
            obj.ValidateEditText.TextAlignment = 'left';
            obj.ValidateEditText.Text = obj.getCygwinLocation();
            
            % Set BrowseButton Properties
            obj.BrowseButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.BrowseButton.Text = message('px4:hwsetup:BrowseButtonText').getString;
            obj.BrowseButton.Position = [340 200 70 20];
            obj.BrowseButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.HELPBLUE;
            % Set callback when finish button is pushed
            obj.BrowseButton.ButtonPushedFcn = @obj.browseDirectory;
            
            %Set ValidateCygwinButton properties
            obj.ValidateCygwinButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.ValidateCygwinButton.Text = message('px4:hwsetup:SetupCygwinToolchain_VerifyInstallation').getString;
            obj.ValidateCygwinButton.Position = [20 170 150 20];
            obj.ValidateCygwinButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.ValidateCygwinButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            % Set callback when finish button is pushed
            obj.ValidateCygwinButton.ButtonPushedFcn = @obj.ValidateButton_callback;
            
            
            %Validation will bring in these widgets
            obj.StatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.StatusTable.Visible = 'off';
            obj.StatusTable.Enable = 'off';
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {''};
            obj.StatusTable.ColumnWidth = [20 390];
            obj.StatusTable.Position = [20 5 390 150];
            
            %checking if
            %run-console_Simulink.bat file is present or not.
            if ~obj.isCygwinFolderValidated(obj.Workflow.HardwareInterface.CygwinDir)
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
            else
                obj.NextButton.Enable = 'on';
            end
            
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';
            
            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';
            
            % Set the Help Text
            obj.HelpText.WhatToConsider =  message('px4:hwsetup:SetupCygwinToolchain_WhatToConsider').getString;
            obj.HelpText.AboutSelection = message('px4:hwsetup:SelectToolchain_AboutSel_Cygwin').getString;
            
        end
        
        function reinit(obj)
            % Disable BusySpinner
            obj.BusySpinner.Visible = 'off';
            obj.StatusTable.Visible = 'off';
            %checking if
            %run-console_Simulink.bat file is present or not.
            if ~obj.isCygwinFolderValidated(obj.Workflow.HardwareInterface.CygwinDir)
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
            end
            
        end
        
        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner.Text = message('px4:hwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();
            
            %checking if
            %run-console_Simulink.bat file is present or not.
            if ~obj.isCygwinFolderValidated(obj.Workflow.HardwareInterface.CygwinDir)
                %Ifrun-console_Simulink.bat is not present, an error is thrown and
                %the user is prevented from going to the next screen.
                error(message('px4:hwsetup:SelectToolchain_Error').getString);
            else
                %If run-console_Simulink.bat is present, then go to next
                %screen
                out = 'codertarget.pixhawk.hwsetup.ValidatePX4';
            end
        end%End of getNextScreenID function
        
    end
    
    methods(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?matlab.unittest.TestCase})
        % TemplateTester needs access to this function to create batch
        % files for Cygwin on the go in Dynapro.
        function createCustomBatFiles(obj)
            
            %Give the complete path to the bash to avoid other 'bash' from
            %executing
            bashPath = fullfile(obj.Workflow.HardwareInterface.CygwinDir, 'toolchain','cygwin64','bin','bash');
            %Find out the java path for building jmavsim
            cygwinJavaPath = fullfile(obj.Workflow.HardwareInterface.CygwinDir, 'toolchain','jdk');
            % Convert windows path to Unix format
            cygwinJavaPath = strrep(cygwinJavaPath , ':', '');
            cygwinJavaPath = strrep(cygwinJavaPath , '\', '/');
            cygwinJavaPath = ['/cygdrive/' lower(cygwinJavaPath(1)) cygwinJavaPath(2:end)];
            %Commands to run
            ADDITIONALTEXT = {['CALL ',bashPath,' -l -c "export JAVA_HOME="' cygwinJavaPath '";%~1"'],...
                ['CALL ',bashPath,' -l -c "export JAVA_HOME="' cygwinJavaPath '";%~1 &"'],...
                ['CALL ',bashPath,' -l -c "cd %1;cd Firmware;',...
                'echo SUBMODULEUPDATESTART;git submodule update --init --recursive;echo SUBMODULEUPDATEEND;',...
                'echo BUILDSTARTING_%4 >>%3;echo CMAKE Config selected : %2 >>%3;make %2 2>>%3;echo BUILDCOMPLETE_%4 >>%3"'],...
                ['CALL ',bashPath,' -l -c "cd %1;git checkout ' obj.Workflow.GITTAG '"'],...
                ['CALL ',bashPath,' -l -c "cd %1;git describe --tags"']};
            for kk = 1:length(obj.FILES)
                obj.createFile(obj.FILES{kk},ADDITIONALTEXT{kk});
            end
            
        end%End of createCustomBatFiles
    end
    
    methods(Access = 'private')
        function editCallbackFcn(obj,~,~)
            if ~strcmp(fullfile(obj.ValidateEditText.Text,filesep),...
                    fullfile(obj.Workflow.HardwareInterface.CygwinDir,filesep))
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
                % Hide all these widgets
                obj.StatusTable.Visible = 'off';
            end
            drawnow;
        end
        
        function browseDirectory(obj, ~, ~)
            % browseDirectory - Callback when browse button is pushed that launches the
            % file browsing window set to the directory indicated by obj.ValidateEditText.Text
            dir = uigetdir(obj.ValidateEditText.Text);
            
            if dir % If the user cancels the file browser, uigetdir returns 0.
                % When a new location is selected, then set that location value
                % back to show it in edit text area. (ValidateEditText.Text).
                obj.ValidateEditText.Text = dir;
                
            end
        end%End of browseDirectory
        
        function ValidateButton_callback(obj,~,~)
            % ValidateButton_callback - Callback when ValidateCygwinButton button is pushed
            
            %Enable the BusySpinner while Firmware validation is taking
            %place
            % Disable the NEXT Button
            obj.NextButton.Enable = 'off';
            %Set the Busy Spinner text
            obj.BusySpinner.Text = message('px4:hwsetup:SelectToolchain_validating').getString;
            obj.BusySpinner.show();
            drawnow;
            ValidateSuccess = true;
            try
                %Check if the folder is valid
                if ~isfolder(fullfile(obj.ValidateEditText.Text))
                    px4.internal.util.CommonUtility.localizedError('px4:hwsetup:SelectToolchain_Invalid_Folder');
                end
                
                obj.verifyCygwinFolder();
                cygwinFWFolder = fullfile(obj.ValidateEditText.Text,'home','Firmware');
                
                % Update the value of the CygwinDir based on the new
                % location which user selects.
                obj.Workflow.HardwareInterface.CygwinDir = obj.ValidateEditText.Text;
                obj.createCustomBatFiles();
                %Check if the user has downloaded the Firmware from the Cygwin
                %installation setup. If yes, then Firmware folder is present
                %inside the home folder.
                if isfolder(cygwinFWFolder)
                    obj.Workflow.HardwareInterface.cygwinCheckout(obj.ValidateEditText.Text,cygwinFWFolder);
                end
                cygwinVer = obj.Workflow.HardwareInterface.getCygwinVersion(obj.ValidateEditText.Text);
                if ~strcmp(cygwinVer, obj.Workflow.CYGWIN_TOOLCHAIN_VERSION)
                    px4.internal.util.CommonUtility.localizedError('px4:hwsetup:SetupCygwinToolchain_UnsupportedVersion', cygwinVer);
                end
            catch EX
                ValidateSuccess = false;
                obj.EnableStatusTable(EX.identifier,EX.message);
            end
            
            %Disable the BusySpinner after validation complete
            obj.BusySpinner.Visible = 'off';
            drawnow;
            
            if ValidateSuccess
                obj.NextButton.Enable = 'on';
                obj.EnableStatusTable('success',message('px4:hwsetup:SelectToolchain_CygwinPass').getString);
            else
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
            end
        end%End of ValidateButton_callback
        
        function verifyCygwinFolder(obj)
            %verifyCygwinFolder - Validates the folder by checking if
            %run-console.bat file is present or not.
            if any(regexp(obj.ValidateEditText.Text,'[!@#$%^&*() ]'))
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:FWFolderNameNotSupported');
            end
            if ~isfile(fullfile(obj.ValidateEditText.Text,'run-console.bat'))
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:SelectToolchain_Invalid_Folder');
            end
        end%End of verifyCygwinFolder
        
        function EnableStatusTable(obj,message_id,message_detail)
            % Show all these widgets
            obj.StatusTable.Visible = 'on';
            obj.StatusTable.Enable = 'on';
            obj.StatusTable.Steps = {message_detail};
            drawnow;
            switch message_id
                case 'success'
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                case 'px4:hwsetup:SelectToolchain_CopyFail'
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                case 'px4:hwsetup:SelectToolchain_Invalid_Folder'
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                case 'px4:hwsetup:SetupCygwinToolchain_UnsupportedVersion'
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                otherwise
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
            end
            drawnow;
        end%End of EnableStatusTable
        
        function location = getCygwinLocation(obj)
            try
                location = codertarget.pixhawk.internal.getPX4CygwinDir();
                if isempty(location)
                    location = obj.getDefaultCygwinDir();
                end
            catch
                %Default suggested location as per documentation
                location = obj.getDefaultCygwinDir();
            end
        end%End of getCygwinLocation
        
        function location = getDefaultCygwinDir(obj)
            location = obj.Workflow.HardwareInterface.DEFAULTCYGWININSTALLDIR;
        end
        
        function createFile(obj,file,text)
            try
                %This function modifies the Test CMakelist include paths
                %according to the user's matlabroot
                defaultBatFile = fullfile(obj.Workflow.HardwareInterface.CygwinDir,'run-console.bat');
                newBatFile = fullfile(obj.Workflow.HardwareInterface.CygwinDir,file);
                if isfile(newBatFile)
                    %If the custom batch files are already there, delete
                    %them before creating new ones
                    delete(newBatFile);
                end
                fileID = fopen(defaultBatFile);
                defaultBatFile_cell_array = textscan( fileID, '%s', 'Delimiter','\n', 'whitespace', '', 'CollectOutput',true );
                fclose(fileID);
                
                defaultBatFile_cell_array = defaultBatFile_cell_array{1};
                index = find(contains(defaultBatFile_cell_array,'CALL bash'), 1);
                hs = StringWriter;
                % Copy the lines from the original run-console.bat file as it is
                % till the line containing 'CALL bash'
                for i=1:index-1
                    hs.addcr(defaultBatFile_cell_array{i});
                end
                hs.addcr('PUSHD %~dp0');
                hs.addcr(text);
                if strcmp(file,'run-console_Simulink.bat') ||...
                        strcmp(file,'run-console_SimulinkBackGnd.bat')
                    for j=1:numel(obj.ERRORLEVELTEXT)
                        hs.addcr(obj.ERRORLEVELTEXT{j});
                    end
                end
                hs.addcr('POPD');
                hs.write(newBatFile);
                
            catch ME
                px4.internal.util.CommonUtility.localizedError(ME.identifier);
            end
        end
        
    end
    
    
    methods(Static)
        
        function filePresent = isCygwinFolderValidated(cygwinroot)
            %Returns true if run-console_Simulink.bat is present
            filePresent = isfile(fullfile(cygwinroot,'run-console_Simulink.bat'));
        end
        
    end
    
end
