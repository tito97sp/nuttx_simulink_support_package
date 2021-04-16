classdef SetupComplete < matlab.hwmgr.internal.hwsetup.LaunchExamples
    %SetupComplete This is an PX4 specific implementation of a
    %Launch Examples screen. This screen will be displayed at the end of
    %the PX4 Setup to give the installer an option to open the examples
    %page for PX4
    
    % Copyright 2018-2020 The MathWorks, Inc.
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % Additional Description - Description for the screen (Label)
        AdditionalDescription
    end
    methods
        function obj = SetupComplete(workflow)
            obj@matlab.hwmgr.internal.hwsetup.LaunchExamples(workflow);
            obj.customizeScreen();
        end
        
        function customizeScreen(obj)
            if strcmp(obj.Workflow.BoardName,message('px4:hwinfo:CustomBoard').getString)
                obj.Description.Text = message('px4:hwsetup:SetupComplete_text','your board').getString;
            else
                obj.Description.Text = message('px4:hwsetup:SetupComplete_text',obj.Workflow.BoardName).getString;
            end
            obj.Description.Position = [20 330 430 40];
            obj.AdditionalDescription = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);

            %Additional text
            if strcmp(obj.Workflow.BoardName,message('px4:hwinfo:Crazyflie2_0').getString) || ...
				strcmp(obj.Workflow.BoardName,message('px4:hwinfo:CustomBoard').getString)
                obj.AdditionalDescription.Text = message('px4:hwsetup:SetupComplete_Additional_text_Crazyflie2_0',obj.Workflow.BoardName).getString;
            else
                obj.AdditionalDescription.Text = message('px4:hwsetup:SetupComplete_Additional_text',obj.Workflow.BoardName).getString;			
            end
            obj.AdditionalDescription.Position = [20 240 430 70];
            %if the LaunchCheckbox is empty then there are no examples to
            %display. Set the ShowExamples property as is appropriate.
            if ~isempty(obj.LaunchCheckbox)
                obj.LaunchCheckbox.Position = [20 100 430 20];
                obj.LaunchCheckbox.ValueChangedFcn = @obj.checkboxCallback;
                obj.LaunchCheckbox.Value=obj.Workflow.ShowExamples;                
            else
                obj.Workflow.ShowExamples = false;
            end
            obj.CancelButton.Visible='off';
        end
        
        function reinit(obj)
            obj.customizeScreen();
        end
    end
    
    
    methods
        function id = getPreviousScreenID(obj)
            if strcmp(obj.Workflow.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                id = 'codertarget.pixhawk.hwsetup.TestConnectionHostTarget';
            else
                id = 'codertarget.pixhawk.hwsetup.TestConnection';
            end
        end
    end
    
    methods(Access = 'private')
        function checkboxCallback(obj, src, ~)
            obj.Workflow.ShowExamples = src.Value;
        end
    end
    
end
