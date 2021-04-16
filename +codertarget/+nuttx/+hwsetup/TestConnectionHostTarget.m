classdef TestConnectionHostTarget < matlab.hwmgr.internal.hwsetup.VerifyHardwareSetup
    % TestConnectionHostTarget - This screen helps the user determine if
    % the PX4 Host Target is ready for Connected IO/ Code-generation
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        %Description text for the screen
        ScreenDescription
    end
    
    properties(Access = private)
        maxAltitudeFC = 20;
        maxAltitudePF = 25;
    end
    
    methods
        
        % Constructor implementation
        function obj = TestConnectionHostTarget(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.VerifyHardwareSetup(varargin{:});
            obj.Title.Text = message('px4:hwsetup:TestConn_Title').getString;
            
            obj.ScreenDescription = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenDescription.Position = [20 200 420 150];
            
            altitudeReached = obj.maxAltitudePF; %#ok<NASGU>
            if strcmp(obj.Workflow.HardwareInterface.SimulinkAlgorithm, message('px4:hwsetup:SelectAlgorithm_FlightController').getString)
                altitudeReached = obj.maxAltitudeFC; %#ok<NASGU>
            end
            obj.ScreenDescription.Text = message('px4:hwsetup:TestConnHostTarget_Description').getString;
            
            % Set HelpText Properties
            obj.HelpText.WhatToConsider = message('px4:hwsetup:TestConnHostTarget_What_to_consider').getString;
            
            % Set DeviceInfo Table Properties
            obj.DeviceInfoTable.Visible = 'off';
            
            % Set Status Table Properties
            obj.StatusTable.Visible = 'off';
            obj.StatusTable.Enable = 'off';
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {''};
            obj.StatusTable.ColumnWidth = [20 350];
            obj.StatusTable.Position = [20 90 440 60];
            
            % Set Test Connection Button Properties
            obj.TestConnButton.Visible = 'on';
            obj.TestConnButton.Text = message('px4:hwsetup:TestConnHostTarget_Button').getString;
            % Set callback when finish button is pushed
            obj.TestConnButton.ButtonPushedFcn = @obj.launchSimulator;
            obj.TestConnButton.Position = [20 180 260 20];
            
            if strcmp(obj.Workflow.BuildExecuted,[obj.Workflow.Px4_Base_Dir,'_True'])
                obj.TestConnButton.Enable = 'on';
            else
                obj.TestConnButton.Enable = 'off';
            end
            % Set HelpText Properties
            obj.HelpText.AboutSelection = '';
        end
        
        function reinit(obj)
            
            %enableScreen enables all the widgets in the screen. make sure
            %to disable the ones you need.
            obj.enableScreen();
            obj.StatusTable.Visible = 'off';
            if strcmp(obj.Workflow.BuildExecuted,[obj.Workflow.Px4_Base_Dir,'_True'])
                obj.TestConnButton.Enable = 'on';
            else
                obj.TestConnButton.Enable = 'off';
            end
            
            if strcmp(obj.Workflow.HardwareInterface.SimulinkAlgorithm, message('px4:hwsetup:SelectAlgorithm_FlightController').getString)
                altitudeReached = obj.maxAltitudeFC; %#ok<NASGU>
            else
                altitudeReached = obj.maxAltitudePF; %#ok<NASGU>
            end
            obj.ScreenDescription.Text = message('px4:hwsetup:TestConnHostTarget_Description').getString;
            
            % Set HelpText Properties
            obj.HelpText.WhatToConsider = message('px4:hwsetup:TestConnHostTarget_What_to_consider').getString;
            
            drawnow;
        end
        
        function launchSimulator(obj, ~, ~)
            sitl = px4.internal.sitl.SimulationInTheLoop.getInstance();
            obj.EnableStatusTable('Busy');
            
            sitl.killSimulatorIfAlreadyOpen();
            % The jMavSim simulator is launched again after it is killed
            % off. Hence killing it again
            sitl.killSimulatorIfAlreadyOpen();
            
            try
                sitl.startPX4HostExecutable();
                obj.EnableStatusTable('HostTargetPass');
            catch
                obj.EnableStatusTable('HostTargetFail');
                return;
            end
            try
                sitl.startSimulatorForSITL();
                obj.EnableStatusTable('SimPass');
            catch
                obj.EnableStatusTable('SimFail');
            end
        end
        
        function id = getPreviousScreenID(obj)
            id = obj.Workflow.HardwareInterface.getPreviousScreenTestConnection(obj.Workflow);
        end
        
        function out = getNextScreenID(~)
            out = 'codertarget.pixhawk.hwsetup.SetupComplete';
        end
    end
    
    methods(Access = private)
        
        function EnableStatusTable(obj,message_arg)
            % Show all these widgets
            obj.StatusTable.Visible = 'on';
            obj.StatusTable.Enable = 'on';
            switch message_arg
                case 'Busy'
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConnHostTarget_Wait').getString, ...
                        message('px4:hwsetup:TestConnSim_Wait').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Busy, ...
                        matlab.hwmgr.internal.hwsetup.StatusIcon.Busy};
                case 'HostTargetPass'
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConnHostTarget_Pass').getString, ...
                        message('px4:hwsetup:TestConnSim_Wait').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass, ...
                        matlab.hwmgr.internal.hwsetup.StatusIcon.Busy};
                case 'SimPass'
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConnHostTarget_Pass').getString, ...
                        message('px4:hwsetup:TestConnSim_Pass').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass, ...
                        matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                case 'HostTargetFail'
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConnHostTarget_Fail').getString, ...
                        message('px4:hwsetup:TestConnSim_Fail').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail, ...
                        matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                case 'SimFail'
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConnHostTarget_Pass').getString, ...
                        message('px4:hwsetup:TestConnSim_Fail').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass, ...
                        matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                otherwise
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConnHostTarget_Pass').getString, ...
                        message('px4:hwsetup:TestConnSim_Pass').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass, ...
                        matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
            end
            
        end
        
        
    end
    
end
