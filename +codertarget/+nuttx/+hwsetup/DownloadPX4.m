classdef DownloadPX4 < matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup
    
    %   DownloadPX4 - Screen implementation which provides the ability to Download
    %   PX4 Firmware on Linux OS
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    properties (Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        %Description text for the screen
        ScreenDescription
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    
    methods
        function obj = DownloadPX4(varargin)
            obj@matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup(varargin{:});
            obj.Title.Text = message('px4:hwsetup:DownloadPX4_Title').getString;
            %Set the Screen Widget properties
            obj.SetScreenWidgets();
            %Initialize the variable to NotStarted
        end
        
        function SetScreenWidgets(obj)
            obj.SelectedImage.ImageFile = '';
            
            obj.Description.Visible = 'off';
            
            obj.ScreenDescription = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            
            obj.ScreenDescription.Position = [20 240 430 140];
            obj.ScreenDescription.Text = message('px4:hwsetup:DownPX4_Desc',obj.Workflow.GITTAG).getString;
            
            obj.SelectionRadioGroup.Visible = 'off';
            
            obj.HelpText.AboutSelection = '';
            obj.HelpText.WhatToConsider = obj.Workflow.HardwareInterface.getDownloadPX4HelpText();
        end%End of SetScreenWidgets function
        
        
        function reinit(obj)
            % Disable BusySpinner
            obj.BusySpinner.Visible = 'off';
        end% End of reinit method
        
        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Text = message('px4:hwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();
            out = 'codertarget.pixhawk.hwsetup.ValidatePX4';
        end
        
        
    end% methods end
    
end% end of Class DownloadPX4
