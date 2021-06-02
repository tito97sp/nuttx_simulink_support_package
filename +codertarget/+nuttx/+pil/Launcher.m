classdef Launcher < rtw.connectivity.Launcher
%LAUNCHER is an example target connectivity configuration class

%   Copyright 2007-2012 The MathWorks, Inc.

    methods
        % constructor
        function this = Launcher(componentArgs, builder)
            narginchk(2, 2);
            % call super class constructor
            this@rtw.connectivity.Launcher(componentArgs, builder);
        end
                               
        
        % Start the application
        function startApplication(this)
            narginchk(1, 1);
			% deploy the PIL exe to the target
			hCS = this.getComponentArgs.getConfigInterface.getConfig; 
            tgtInfo = codertarget.targethardware.getTargetHardware(hCS);
            %codertarget.pixhawk.internal.loadAndRun(hCS,0, tgtInfo.Name);
            % pause for reboot
            pause(5);                     

        end
        
        % Stop the application
        function stopApplication(~)                                   

        end
    end
end
