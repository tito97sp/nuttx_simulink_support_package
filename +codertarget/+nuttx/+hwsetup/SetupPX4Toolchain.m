classdef SetupPX4Toolchain < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % SetupPX4Toolchain - Screen implementation to set up the PX4 Toolchain
    % for use with the PX4 Support Package for Autopilots
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties
        %Description text for the screen
        ScreenDescription
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    methods
        
        function obj = SetupPX4Toolchain(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})
            
            % Set the Title Text
            obj.Title.Text = obj.Workflow.HardwareInterface.getSetupPX4ToolchainTitle();
            
            % Set Description Properties
            obj.ScreenDescription = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenDescription.Position = [20 200 430 180];
            
            obj.ScreenDescription.Text = message('px4:hwsetup:SetupPX4Toolchain_Description_linux').getString;
            
            obj.ConfigurationInstructions.Visible = 'off';
            
            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';
            
            % Set the Help Text
            obj.HelpText.WhatToConsider = obj.Workflow.HardwareInterface.getSetupPX4ToolchainHelpText(obj.Workflow);
            obj.HelpText.AboutSelection = '';
        end
        
        function id = getPreviousScreenID(obj)
            id = obj.Workflow.HardwareInterface.getPreviousScreenSetupPX4Toolchain();
        end
        
        function reinit(obj)
            obj.BusySpinner.Visible = 'off';
        end
        
        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Text = message('px4:hwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();
            
            obj.Workflow.HardwareInterface.isToolchainInstalled(obj.Workflow);
            if strcmpi(obj.Workflow.ToolchainInstalled,"NotInstalled")
                %If toolchain is not installed, an error is thrown and
                %the user is prevented from going to the next screen.
                errMsg = obj.Workflow.HardwareInterface.getNextScreenSetupPX4ToolchainErrorMsg();
                obj.BusySpinner.Visible = 'off';
                out = 'codertarget.pixhawk.hwsetup.SetupPX4Toolchain';
                error(errMsg);
            else
                out = 'codertarget.pixhawk.hwsetup.SelectAlgorithm';
            end
        end
        
        
    end
    
end
