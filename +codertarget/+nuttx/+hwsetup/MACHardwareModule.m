classdef MACHardwareModule < codertarget.pixhawk.hwsetup.HardwareInterface
    % MACHardwareModule - Class that covers all hardware specific
    % callbacks in macOS.
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    properties
    end
    
    methods
        
        function obj = MACHardwareModule()
            obj@codertarget.pixhawk.hwsetup.HardwareInterface();
        end
        
        function updatePlatformInfo(~)
            %Do Nothing
        end
        
        function isToolchainInstalled(~,~)
            %Do Nothing
        end
    end
end
