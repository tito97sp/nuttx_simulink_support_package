classdef SelectAlgorithm < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    
    %   SelectAlgorithm - Screen the algorithm to be designed in Simulink.
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        
        % SelectionRadioGroup - Radio button group to display the list of items to choose
        % from (RadioGroup)
        SelectionRadioGroup
        
        %Description text for the screen
        ScreenDescription
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    methods
        
        function obj = SelectAlgorithm(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})
            
            % Set the Title Text
            obj.Title.Text = message('px4:hwsetup:SelectAlgorithm_Title').getString;
            
            % Set Description Properties
            obj.ScreenDescription = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenDescription.Position = [20 200 430 180];
            obj.ScreenDescription.Text = message('px4:hwsetup:SelectAlgorithm_Description').getString;
            obj.SelectionRadioGroup = matlab.hwmgr.internal.hwsetup.RadioGroup.getInstance(obj.ContentPanel);
            obj.ConfigurationInstructions.Visible = 'off';
            
            obj.SelectionRadioGroup.Title = message('px4:hwsetup:SelectAlgorithmRadio_Title').getString;
            obj.SelectionRadioGroup.Items = {message('px4:hwsetup:SelectAlgorithm_FlightController').getString,...
                message('px4:hwsetup:SelectAlgorithm_PathFollower').getString};
            obj.SelectionRadioGroup.Position = [20 180 445 100]; % Position matters for RG
            obj.SelectionRadioGroup.SelectionChangedFcn = @obj.changeSimulinkAlgorithm;
            setpref('MW_PX4_SIMULINK_ALGORITHM', 'AlgorithmType', message('px4:hwsetup:SelectAlgorithm_FlightController').getString);
            
            %Saving the default value
            obj.Workflow.HardwareInterface.SimulinkAlgorithm = obj.SelectionRadioGroup.Value;
            
            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';
            
            % Set the Help Text
            obj.HelpText.WhatToConsider =  '';
            obj.HelpText.AboutSelection = message('px4:hwsetup:SelectAlgorithm_AboutSel_FlightController').getString;
        end
        
        function reinit(obj)
            obj.BusySpinner.Visible = 'off';
        end
        
        function PreviousScreen = getPreviousScreenID(~)
            PreviousScreen = 'codertarget.pixhawk.hwsetup.ValidatePX4';
        end
        
        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Text = message('px4:hwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();
            try
                obj.Workflow.HardwareInterface.revertStartUpScriptIfNeeded(...
                    obj.Workflow);
            catch ME
                obj.BusySpinner.Visible = 'off';
                throw(ME);
            end
            out = obj.Workflow.HardwareInterface.getNextScreenSelectAlgorithm();
        end%End of getNextScreenID function
        
    end
    
    methods(Access = 'private')
        
        function changeSimulinkAlgorithm(obj,~,~)
            
            obj.Workflow.HardwareInterface.SimulinkAlgorithm = obj.SelectionRadioGroup.Value;
            % Storing the algorithm as MATLAB Preferences as the same will be
            % used during setup screens to modify the startup screens
            % accordingly
            setpref('MW_PX4_SIMULINK_ALGORITHM', 'AlgorithmType', obj.Workflow.HardwareInterface.SimulinkAlgorithm);
            switch(obj.SelectionRadioGroup.ValueIndex)
                case 1
                    obj.HelpText.AboutSelection = message('px4:hwsetup:SelectAlgorithm_AboutSel_FlightController').getString;
                case 2
                    obj.HelpText.AboutSelection = message('px4:hwsetup:SelectAlgorithm_AboutSel_PathFollower').getString;
                otherwise
                    obj.HelpText.AboutSelection = message('px4:hwsetup:SelectAlgorithm_AboutSel_FlightController').getString;
            end
        end%end of changeToolchain function
    end
    
end
