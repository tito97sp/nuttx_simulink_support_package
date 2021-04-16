classdef Platform
    %
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    methods (Static)
        function out = getOSPlatformDetails()
            persistent platform;
            if isempty(platform)
                if ispc
                    platform = codertarget.pixhawk.internal.OSPlatform.Windows;
                elseif ismac
                    platform = codertarget.pixhawk.internal.OSPlatform.macOS;
                elseif isunix
                    [status, cmd] = system('lsb_release -a');
                    if ~status
                        if contains(cmd,'Ubuntu')
                            platform = codertarget.pixhawk.internal.OSPlatform.Ubuntu;
                        else
                            platform = codertarget.pixhawk.internal.OSPlatform.Others;
                        end
                    else
                        error(message('px4:hwsetup:SetupPX4Toolchain_Err_Linux_flavour'));
                    end                    
                else
                    platform = codertarget.pixhawk.internal.OSPlatform.Others;
                end
            end
            
            out = platform;
        end%End of getOSPlatformDetails
    end
end
