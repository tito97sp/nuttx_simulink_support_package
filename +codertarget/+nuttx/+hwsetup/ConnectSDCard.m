classdef ConnectSDCard < matlab.hwmgr.internal.hwsetup.TemplateBase
    % ConnectSDCard - This is an information screen which guides the user
    % to add/edit the RC.TXT file in the SD card and then put the SD card
    % back to the board.
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        %Description text for the screen
        ScreenDescription
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    methods
        % Constructor implementation
        function obj = ConnectSDCard(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});
            
            obj.Title.Text = message('px4:hwsetup:ConnSDCard_Title').getString;
            
            obj.ScreenDescription = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            
            obj.ScreenDescription.Position = [20 180 440 200];
            obj.ScreenDescription.Text = message('px4:hwsetup:ConnSDCard_Text').getString ;
            
            % HelpText should be internationalized
            obj.HelpText.AboutSelection =  '';
            obj.HelpText.WhatToConsider = message('px4:hwsetup:ConnSDCard_WhatConsider').getString;
        end
        
        function reinit(obj)
            obj.BusySpinner.Visible = 'off';
        end
        
        function id = getPreviousScreenID(obj)
            id = obj.Workflow.HardwareInterface.getPreviousScreenConnectSDCard();
        end
        
        function out = getNextScreenID(obj)
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Text = message('px4:hwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();
            out = 'codertarget.pixhawk.hwsetup.TestConnection';
        end
    end
    
end
