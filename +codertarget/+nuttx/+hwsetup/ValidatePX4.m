classdef ValidatePX4 < matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup
    
    %   ValidatePX4 - Screen provides the ability to validate
    %   PX4 Firmware on Windows OS
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    properties (Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        AboutText
        % ValidateEditText - Text box area to show install location that has
        % to be validated.
        ValidateEditText
        % BrowseButton - Button that on press opens a filesystem browser
        % for user to pick the correct install location.
        BrowseButton
        % ValidateDownloadButton - Button that on either Downloads the PX4 software,
        % or Validates the existing PX4 firmware that user already has downloaded.
        ValidateDownloadButton
        % Status Table to show the status of validation
        StatusTable
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    methods
        function obj = ValidatePX4(varargin)
            obj@matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup(varargin{:});
            obj.ParentPanel.Visible = 'off';
            obj.Title.Text = message('px4:hwsetup:ValidatePX4_Title').getString;
            obj.ValidateEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            % Set callback when edit box value is changed
            obj.ValidateEditText.ValueChangedFcn = @obj.editCallbackFcn;
            %Set the Screen Widget properties
            obj.SetScreenWidgets();
            obj.ParentPanel.Visible = 'on';
        end
        
        function SetScreenWidgets(obj)
            obj.BrowseButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.ValidateDownloadButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            
            obj.SelectedImage.ImageFile = '';
            
            obj.Description.Text = message('px4:hwsetup:DownValPX4_Desc_2',obj.Workflow.GITTAG).getString;
            pos =  obj.Description.Position;
            obj.Description.Position = [pos(1) pos(2)-40 pos(3) pos(4)+50];
            obj.SelectionRadioGroup.Visible = 'off';
            
            % Set ValidateEditText Properties
            obj.ValidateEditText.Position = [20 230 300 20];
            obj.ValidateEditText.TextAlignment = 'left';
            obj.SetDefaultValidateEditText();
            % Set BrowseButton Properties
            obj.BrowseButton.Text = message('px4:hwsetup:BrowseButtonText').getString;
            obj.BrowseButton.Position = [340 230 70 20];
            obj.BrowseButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.HELPBLUE;
            % Set callback when finish button is pushed
            obj.BrowseButton.ButtonPushedFcn = @obj.browseDirectory;
            drawnow;
            
            % Set ValidateDownloadButton Properties
            obj.ValidateDownloadButton.Text = message('px4:hwsetup:DownValPX4_DownloadText').getString;
            obj.ValidateDownloadButton.Position = [20 200 100 20];
            obj.ValidateDownloadButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.ValidateDownloadButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            % Set callback when finish button is pushed
            obj.ValidateDownloadButton.ButtonPushedFcn = @obj.ValidateButton_callback;
            
            %Validation will bring in these widgets
            obj.StatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.StatusTable.Visible = 'off';
            obj.StatusTable.Enable = 'off';
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {''};
            obj.StatusTable.ColumnWidth = [20 390];
            obj.StatusTable.Position = [20 30 390 160];
            
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';
            
            obj.HelpText.AboutSelection = message('px4:hwsetup:DownValPX4_AbtSel_2').getString;
            obj.HelpText.WhatToConsider = message('px4:hwsetup:DownValPX4_WhatConsider_2').getString;
            obj.ValidateDownloadButton.Text = message('px4:hwsetup:DownValPX4_validateText').getString;
            
            % Disable the NEXT Button
            obj.NextButton.Enable = 'off';
            drawnow;
        end%End of SetScreenWidgets function
        
        function SetDefaultValidateEditText(obj,~,~)
            
            if isempty(obj.Workflow.Px4_Base_Dir)
                obj.ValidateEditText.Text = obj.Workflow.HardwareInterface.getDefaultFWLocation();
            else
                obj.ValidateEditText.Text = obj.Workflow.Px4_Base_Dir;
            end
            
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
        end
        
        function ValidateButton_callback(obj, ~, ~)
            % ValidateButton_callback - Callback when ValidateDownloadButton button is pushed
            
            % Update the value of the Px4_Base_Dir based on the new
            % location which user selects.
            obj.Workflow.Px4_Base_Dir = obj.ValidateEditText.Text;
            
            % Call the PX4FirmwareValidate function when the user has
            % already downloaded the Firmware.
            
            %Enable the BusySpinner while Firmware validation is taking
            %place
            %Disable the Push Buttons
            obj.disableScreen();
            %Set the Busy Spinner text
            obj.BusySpinner.Text = message('px4:hwsetup:DownValPX4_FW_validating').getString;
            obj.BusySpinner.show();
            drawnow;
            ValidateSuccess = true;
            try
                obj.Workflow.HardwareInterface.PX4FirmwareValidate(obj.Workflow);
            catch ME
                ValidateSuccess = false;
                Exception = ME.message;
            end
            %Disable the BusySpinner after validation complete
            obj.BusySpinner.Visible = 'off';
            %Enable the buttons
            obj.enableScreen();
            
            %Enable the Status table to show the status of Download and
            %customization
            obj.EnableStatusTable();
            drawnow;
            if ValidateSuccess
                obj.StatusTable.Steps = {message('px4:hwsetup:DownValPX4_validate_pass').getString};
                obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                if ~isempty(lastwarn)
                    [msg,id] = lastwarn;
                    %Show the warning on the status table
                    if strcmp(id,'px4:hwsetup:DownValPX4_wrong_Firmware')
                        obj.StatusTable.Steps = {msg};
                        obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Warn};
                        %Clear the lastwarn
                        lastwarn('');
                    end
                end
            else
                obj.StatusTable.Steps = {message('px4:hwsetup:DownValPX4_validate_fail',Exception).getString};
                obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
            end
            drawnow
            
        end% End of function ValidateButton_callback
        
        function editCallbackFcn(obj,~,~)
            if ~strcmp(fullfile(obj.ValidateEditText.Text,filesep),...
                    fullfile(obj.Workflow.Px4_Base_Dir,filesep))
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
                % Hide all these widgets
                obj.StatusTable.Visible = 'off';
                %obj.StatusTable.Enable = 'off';
            end
        end
        
        function EnableStatusTable(obj)
            
            % Show all these widgets
            obj.StatusTable.Visible = 'on';
            obj.StatusTable.Enable = 'on';
        end
        
        %
        
        function reinit(obj)
            % Disable BusySpinner
            obj.BusySpinner.Visible = 'off';
            obj.StatusTable.Visible = 'off';
            
        end% End of reinit method
        
        
        function PreviousScreen = getPreviousScreenID(obj)
            PreviousScreen = obj.Workflow.HardwareInterface.getPreviousScreenValidatePX4();
        end
        
        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Text = message('px4:hwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();
            
            out = obj.Workflow.HardwareInterface.getNextScreenValidatePX4(obj.Workflow);
        end
        
    end% methods end
    
end% end of Class ValidatePX4
