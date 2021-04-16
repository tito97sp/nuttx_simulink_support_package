classdef (Hidden = true) SerialLauncher < rtw.connectivity.Launcher
%SERIALLAUNCHER Launches the application built by a BUILDER object
%

%   Copyright 2019 The MathWorks, Inc.
            
   
    %% Public methods
    methods
        function this = SerialLauncher(componentArgs, builder)
            narginchk(2, 2);
            % call super class constructor
            this@rtw.connectivity.Launcher(componentArgs, builder);
        end                                
        
        function startApplication(this)
			narginchk(1, 1);
			% deploy the PIL exe to the target
			hCS = this.getComponentArgs.getConfigInterface.getConfig; 
            tgtInfo = codertarget.targethardware.getTargetHardware(hCS);
            codertarget.pixhawk.internal.loadAndRun(hCS,0, tgtInfo.Name);
            % pause for reboot
            pause(5);
        end
        
        function stopApplication(~)
            
        end
    end
end
