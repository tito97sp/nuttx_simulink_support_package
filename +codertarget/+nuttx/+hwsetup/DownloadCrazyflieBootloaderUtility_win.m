classdef DownloadCrazyflieBootloaderUtility_win < matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup
    
    %   DownloadCrazyflieBootloaderUtility_linux - This screens helps in
    %   download and validation of the STM32 tools in windows for bootloader
    %   update of the Crazyflie drone
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        AboutText
        % ValidateEditText - Text box area to show install location that has
        % to be validated.
        
        %Link to STM32 DFU utils
        LinktoSTM32_DFU_util
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    methods
        function obj = DownloadCrazyflieBootloaderUtility_win(varargin)
            obj@matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup(varargin{:});
            obj.ParentPanel.Visible = 'off';
            obj.Title.Text = message('px4:hwsetup:DownloadCrazyBootUtil_Title').getString;
            
            %Set the Screen Widget properties
            obj.SetScreenWidgets();
            obj.ParentPanel.Visible = 'on';
        end
        
        function SetScreenWidgets(obj)
            obj.SelectedImage.ImageFile = '';
            obj.Description.Text = message('px4:hwsetup:DownloadCrazyBootUtil_Desc_win').getString;
            pos =  obj.Description.Position;
            obj.Description.Position = [pos(1) pos(2)-40 pos(3) pos(4)+50];
            obj.SelectionRadioGroup.Visible = 'off';
            
            obj.HelpText.AboutSelection = message('px4:hwsetup:DownloadCrazyBootUtil_AbtSel_win').getString;
            obj.HelpText.WhatToConsider = '';
            
            %Set Link Properties
            obj.LinktoSTM32_DFU_util = matlab.hwmgr.internal.hwsetup.HelpText.getInstance(obj.ContentPanel);
            obj.LinktoSTM32_DFU_util.Additional = ['<font size="4">' message('px4:hwsetup:DownloadCrazyBootUtil_Link').getString '</font>'];
            obj.LinktoSTM32_DFU_util.Position = [20 250 300 30];
            obj.LinktoSTM32_DFU_util.AboutSelection = '';
            obj.LinktoSTM32_DFU_util.WhatToConsider = '';
        end%End of SetScreenWidgets function
        
        function reinit(obj)
            % Disable BusySpinner
            obj.BusySpinner.Visible = 'off';
        end% End of reinit method
        
        
        function PreviousScreen = getPreviousScreenID(~)
            PreviousScreen ='codertarget.pixhawk.hwsetup.SelectCMAKEandHardware';
        end
        
        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Text = message('px4:hwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();
            
            out = 'codertarget.pixhawk.hwsetup.Validate_DFU_utils';
        end
        
    end% methods end
    
end% end of Class DownloadCrazyflieBootloaderUtility_win
