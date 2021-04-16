classdef UploadCrazyflieBootloader < matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup
    
    %   UploadCrazyflieBootloader - This screen enable the users to flash
    %   the bootloader to the Crazyflie drone.
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        AboutText
        % UploadBootloaderButton - Button that on either Downloads the PX4 software,
        % or Validates the existing PX4 firmware that user already has downloaded.
        UploadBootloaderButton
        % Status Table to show the status of validation
        StatusTable
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    methods
        function obj = UploadCrazyflieBootloader(varargin)
            obj@matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup(varargin{:});
            obj.ParentPanel.Visible = 'off';
            obj.Title.Text = message('px4:hwsetup:UploadCrazyflieBootloader_Title').getString;
            %Set the Screen Widget properties
            obj.SetScreenWidgets();
            obj.ParentPanel.Visible = 'on';
        end
        
        function SetScreenWidgets(obj)
            obj.UploadBootloaderButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            
            obj.SelectedImage.ImageFile = '';
            
            obj.Description.Text = message('px4:hwsetup:UploadCrazyflieBootloader_Desc').getString;
            pos =  obj.Description.Position;
            obj.Description.Position = [pos(1) pos(2)-100 pos(3) pos(4)+110];
            obj.SelectionRadioGroup.Visible = 'off';
            
            % Set UploadBootloaderButton Properties
            obj.UploadBootloaderButton.Text = message('px4:hwsetup:UploadButtonText').getString;
            obj.UploadBootloaderButton.Position = [20 181 120 20];
            obj.UploadBootloaderButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.UploadBootloaderButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            % Set callback when finish button is pushed
            obj.UploadBootloaderButton.ButtonPushedFcn = @obj.UploadBootloaderButton_callback;
            
            %Validation will bring in these widgets
            obj.StatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.StatusTable.Visible = 'off';
            obj.StatusTable.Enable = 'off';
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {''};
            obj.StatusTable.ColumnWidth = [20 390];
            obj.StatusTable.Position = [20 1 390 70];
            
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';
            
            obj.HelpText.AboutSelection = '';
            obj.HelpText.WhatToConsider = message('px4:hwsetup:UploadCrazyflieBootloader_WhatConsider').getString;
            obj.UploadBootloaderButton.Text = message('px4:hwsetup:UploadButtonText').getString;
            
            imgDir = obj.Workflow.HardwareInterface.getImageDir(obj.Workflow,'screens');
            % Set the default Image to be displayed for Pixhawk 1
            obj.SelectedImage.ImageFile = fullfile(imgDir, 'crazyflie2_0_on_off.PNG');
            obj.SelectedImage.Position = [200 85 230 250/2];
            
            % Disable the NEXT Button
            obj.NextButton.Enable = 'off';
        end%End of SetScreenWidgets function
        
        function UploadBootloaderButton_callback(obj, ~, ~)
            % ValidateButton_callback - Callback when UploadBootloaderButton button is pushed
            
            %Enable the BusySpinner while Firmware validation is taking
            %place
            %Disable the Push Buttons
            obj.disableScreen();
            %Set the Busy Spinner text
            obj.BusySpinner.Text = message('px4:hwsetup:Firmware_updating').getString;
            obj.BusySpinner.show();
            ValidateSuccess = true;
            try
                obj.Workflow.HardwareInterface.UploadCrazyflieBootloader(obj.Workflow);
                a = msgbox(message('px4:hwsetup:CrazyflieBootUpdateNote').getString);
                uiwait(a);
            catch
                ValidateSuccess = false;
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
                obj.StatusTable.Steps = {message('px4:hwsetup:DFU_upload_pass').getString};
                obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
            else
                obj.StatusTable.Steps = {message('px4:hwsetup:DFU_upload_failed').getString};
                obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
            end
            
        end% End of function ValidateButton_callback
        
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
        
        
        function PreviousScreen = getPreviousScreenID(~)
            PreviousScreen = 'codertarget.pixhawk.hwsetup.Validate_DFU_utils';
        end
        
        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Text = message('px4:hwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();
            
            out = 'codertarget.pixhawk.hwsetup.BuildPX4FirmwareCommon';
        end
        
    end% methods end
    
end% end of Class UploadCrazyflieBootloader
