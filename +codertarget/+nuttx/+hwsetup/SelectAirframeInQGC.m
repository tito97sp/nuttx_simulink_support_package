classdef SelectAirframeInQGC < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    
    %   SelectAirframeInQGC - Screen provides the instructions to select
    %   the appropriate airframe for user's drone in QGroundControl. This
    %   is essential for path follower application where goal is to reuse
    %   the default PX4 controller. Upon selecting the airframe in QGC, rCS
    %   automatically selects the correct the controller and mixer in
    %   background.
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        
        %Description text for the screen
        ScreenDescription
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    properties (Access = private)
        % module to disable
        moduleToDisable = {'navigator start'};
    end
    
    methods
        
        function obj = SelectAirframeInQGC(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})
            
            % Set the Title Text
            obj.Title.Text = message('px4:hwsetup:SelectAirframeInQGC_Title').getString;
            %Default position is [20 7 470 25], But increasing it to accommodate the lengthier title
            obj.Title.Position = [20 7 550 25];
            
            % Set Description Properties
            obj.ScreenDescription = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenDescription.Position = [20 200 430 180];
            obj.ScreenDescription.Text = message('px4:hwsetup:SelectAirframeInQGC_Description').getString;
            obj.ConfigurationInstructions.Visible = 'off';
            
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';
            
            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';
            
            % Set the Help Text
            obj.HelpText.WhatToConsider =  message('px4:hwsetup:SelectAirframeInQGC_WhatToConsider').getString;
            obj.HelpText.AboutSelection = '';
            
        end
        
        function reinit(obj)
            obj.BusySpinner.Visible = 'off';
        end
        
        function PreviousScreen = getPreviousScreenID(~)
            PreviousScreen = 'codertarget.pixhawk.hwsetup.SelectCMAKEandHardware';
        end
        
        function NextScreen = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner.Text = message('px4:hwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();
            
            try
                obj.Workflow.HardwareInterface.modifyStartupScript(...
                    obj.Workflow, obj.moduleToDisable);
            catch ME
                obj.BusySpinner.Visible = 'off';
                throw(ME);
            end
            NextScreen =  'codertarget.pixhawk.hwsetup.BuildPX4FirmwareCommon';
        end%End of getNextScreenID function
        
    end
    
end
