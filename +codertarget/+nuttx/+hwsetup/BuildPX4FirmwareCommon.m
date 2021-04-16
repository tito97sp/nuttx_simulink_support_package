classdef BuildPX4FirmwareCommon < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % BuildPX4Firmware - Screen implementation to enable users to build the
    % PX4 Firmware on Windows and Linux OS.
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % Button to open Add-On Explorer
        BuildButton
        % Status Table to show the status of validation
        StatusTable
        % ValidateEditText - Text box area to show install location that has
        % to be validated.
        ValidateEditText
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    methods
        function obj = BuildPX4FirmwareCommon(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})
            obj.ParentPanel.Visible = 'off';
            % Create button widget and parent it to the content panel
            obj.BuildButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel); % Button
            
            % Set the Title Text
            obj.Title.Text = message('px4:hwsetup:BuildPX4Firmware_Title').getString;
            
            obj.ValidateEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            
            %Set Busy Spinner Properties
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';
            
            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';
            
            %Validation will bring in these widgets
            obj.StatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.StatusTable.Visible = 'off';
            obj.StatusTable.Enable = 'off';
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {''};
            
            %Set BuildButton Properties
            obj.BuildButton.Text = message('px4:hwsetup:BuildPX4Firmware_Button').getString;
            obj.BuildButton.ButtonPushedFcn = @obj.buttonCallback;
            obj.BuildButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.BuildButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            
            obj.setScreenProperty();
            % Set the Help Text
            obj.HelpText.AboutSelection = '';
            obj.ParentPanel.Visible = 'on';
        end
        
        function setScreenProperty(obj)
            
            if obj.Workflow.isCustomConfig
                %If Custom CMAKE
                % Set ValidateEditText Properties
                obj.ValidateEditText.Position = [20 190 430 20];
                obj.ValidateEditText.TextAlignment = 'left';
                obj.ValidateEditText.Enable = 'on';
                obj.ValidateEditText.Visible = 'on';
                if obj.Workflow.isCustomConfig
                    obj.ValidateEditText.Text = ['make ',obj.Workflow.Px4_Cmake_Config];
                end
                obj.BuildButton.Position = [20 160 200 20];
                obj.StatusTable.Position = [20 60 400 90];
                % Set Description Properties
                obj.ConfigurationInstructions.Text = message('px4:hwsetup:BuildPX4Firmware_Description_with_editBox',...
                    fullfile(obj.Workflow.Px4_Base_Dir,'Firmware')).getString;
                obj.ConfigurationInstructions.Position = [20 190 430 180];
                obj.HelpText.WhatToConsider = message('px4:hwsetup:BuildPX4Firmware_WhatConsider_with_editBox_Linux').getString;
                
            else
                obj.ValidateEditText.Visible = 'off';
                obj.BuildButton.Position = [20 220 200 20];
                % Set Description Properties
                obj.ConfigurationInstructions.Text = message('px4:hwsetup:BuildPX4Firmware_Description_Linux',...
                    fullfile(obj.Workflow.Px4_Base_Dir,'Firmware')).getString;
                obj.ConfigurationInstructions.Position = [20 240 430 130];
                obj.StatusTable.Position = [20 120 400 90];
                obj.HelpText.WhatToConsider = message('px4:hwsetup:BuildPX4Firmware_WhatConsider_Linux').getString;
            end
            
            FWImage = obj.Workflow.HardwareInterface.getPX4FirmwareImage(obj.Workflow);
            %Make the Build Firmware compulsory if the Firmware Image is
            %not present
            if isempty(FWImage)
                obj.NextButton.Enable = 'off';
            else
                obj.NextButton.Enable = 'on';
            end
            
        end %End of setScreenProperty method
        
        
        function reinit(obj)
            
            obj.BusySpinner.Visible = 'off';
            obj.enableScreen();
            %Set the Description and Edit Text property based on type of
            %CMAKE selected
            obj.setScreenProperty();
            obj.SetStatusTable('off');
        end
        
        
        function id = getPreviousScreenID(obj)
            id =  obj.Workflow.HardwareInterface.getPreviousScreenBuildPX4Firmware(obj.Workflow);
        end
        
        
        function buttonCallback(obj,~,~)
            
            GitTargetDir = obj.Workflow.Px4_Firmware_Dir;
            obj.SetStatusTable('off');
            if obj.Workflow.isCustomConfig
                %Check if all words are strings/char
                %Check number of words. Should be 2 only
                %Check if 'make' is present as first word
                %Ensure upload/test is not there
                
                buildCommand = string(strsplit(strtrim(obj.ValidateEditText.Text)));
                if numel(buildCommand)~=2
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                    if numel(buildCommand)==3
                        if any(strcmp(buildCommand(:),'upload')) || any(strcmp(buildCommand(:),'test'))
                            obj.StatusTable.Steps = {message('px4:hwsetup:BuildPX4Firmware_Fail_UploadTest').getString};
                            return
                        end
                    end
                    obj.StatusTable.Steps = {message('px4:hwsetup:BuildPX4Firmware_Fail_3Args').getString};
                    return
                end
                if (~strcmp(buildCommand(1),'make'))
                    obj.StatusTable.Steps = {message('px4:hwsetup:BuildPX4Firmware_Fail_NoMake').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                    return
                end
                buildCommand =char(buildCommand(2));
            else
                buildCommand = [];
            end
            
            %Get the current date timestamp in the format: eg-> 07-Jun-2018_18-06-25
            obj.Workflow.BuildTimeStamp = obj.Workflow.HardwareInterface.getCurrentDateTime();
            
            %Disable the screen before starting BusySpinner
            obj.disableScreen();
            %Enable the BusySpinner while Firmware build is taking
            %place
            obj.BusySpinner.Text = message('px4:hwsetup:BuildPX4Firmware_building').getString;
            obj.BusySpinner.show();
            drawnow;
            try
                if strcmp(obj.Workflow.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                    %build IO firmware
                    obj.Workflow.HardwareInterface.PX4IOFirmwareBuild(obj.Workflow,GitTargetDir,obj.Workflow.BuildTimeStamp,buildCommand);
                    %copy files to px4_simulink_app for test connection
                    obj.Workflow.HardwareInterface.customizePX4FirmwareForSITL(obj.Workflow)
                    %build firmware for test connection
                    obj.Workflow.HardwareInterface.PX4FirmwareBuild(obj.Workflow,GitTargetDir,obj.Workflow.BuildTimeStamp,buildCommand);
                elseif strcmp(obj.Workflow.BoardName, message('px4:hwinfo:Crazyflie2_0').getString) ...
                        || strcmp(obj.Workflow.BoardName,message('px4:hwinfo:CustomBoard').getString)
                    obj.Workflow.HardwareInterface.PX4FirmwareBuild(obj.Workflow,GitTargetDir,obj.Workflow.BuildTimeStamp,buildCommand);
                else
                    obj.Workflow.HardwareInterface.PX4IOFirmwareBuild(obj.Workflow,GitTargetDir,obj.Workflow.BuildTimeStamp,buildCommand);
                end

                BuildSuccess = true;
            catch ME
                BuildSuccess = false;
                Exception = ME.message;
            end
            %Disable the BusySpinner after build complete
            obj.BusySpinner.Visible = 'off';
            obj.enableScreen();
            %Enable the Status table to show the status of Download
            obj.SetStatusTable('on');
            if BuildSuccess
                obj.StatusTable.Steps = {message('px4:hwsetup:BuildPX4Firmware_Pass').getString};
                obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                if obj.Workflow.isCustomConfig
                    %If custom config is selected, the update the value of
                    %the config in workflow variable (customer could have edited), so that it will be
                    %saved for creating thirdparty.xml
                    obj.Workflow.Px4_Cmake_Config = buildCommand;
                end
                %Setting the variable to true to indicate that Build Firmware has
                %been executed using this screen
                obj.Workflow.BuildExecuted = [obj.Workflow.Px4_Base_Dir,'_True'];
                
                %Set the FirmwareUploaded flag to false, as the latest
                %Firmware built is not uploaded
                obj.Workflow.FirmwareUploaded = false;
            else
                obj.StatusTable.Steps = {message('px4:hwsetup:BuildPX4Firmware_Fail',Exception).getString};
                obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                obj.NextButton.Enable = 'off';
                %Setting the variable to false
                obj.Workflow.BuildExecuted = [obj.Workflow.Px4_Base_Dir,'_False'];
            end
            
        end
        
        function out = getNextScreenID(obj)
            obj.disableScreen();
            % Enable BusySpinner
            %Set the Busy Spinner text
            obj.StatusTable.Visible = 'off';
            obj.BusySpinner.Text = message('px4:hwsetup:BuildPX4Firmware_Register_Tokens').getString;
            obj.BusySpinner.show();
            try
                % Now call 3PToolRegistration API
                %Set the busy Spinner on, while token registrations are taking
                %place
                obj.Workflow.HardwareInterface.ThirdPartyToolsRegistration(obj.Workflow);
                obj.Workflow.HardwareInterface.registerTPTOkens();
            catch ME
                %Disable Busy Spinner
                obj.BusySpinner.Visible = 'off';
                obj.enableScreen();
                obj.StatusTable.Steps = {message('px4:hwsetup:TestConn_Register_Token_Fail',ME.message).getString};
                obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                obj.StatusTable.Visible = 'on';
                obj.StatusTable.Enable = 'on';
                out = '';
                return;
            end
            out = obj.Workflow.HardwareInterface.getNextScreenBuildPX4Firmware(obj.Workflow);
        end
    end
    
    methods(Access = private)
        
        function SetStatusTable(obj,status)
            if strcmpi(status,'on')
                % Show all these widgets
                obj.StatusTable.Visible = 'on';
                obj.StatusTable.Enable = 'on';
            elseif strcmpi(status,'off')
                obj.StatusTable.Visible = 'off';
                obj.StatusTable.Enable = 'off';
            end
        end
    end
end
