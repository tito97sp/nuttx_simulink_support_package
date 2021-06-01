classdef ConnectivityConfig < rtw.connectivity.Config
%CONNECTIVITYCONFIG is an example target connectivity configuration class
    
%   Copyright 2007-2016 The MathWorks, Inc.
    
    methods
        % Constructor
        function this = ConnectivityConfig(componentArgs)

            % A target application framework specifies additional source files and libraries
            % required for building the executable
            targetApplicationFramework = ...
                codertarget.nuttx.pil.TargetApplicationFramework(componentArgs);
            
            
            % Create an instance of MakefileBuilder; this works in conjunction with your
            % template makefile to build the PIL executable
            builder = codertarget.nuttx.pil.MakefileBuilder(componentArgs, ...
                targetApplicationFramework, ...
                '.bin');
            
            % Launcher
            launcher = codertarget.nuttx.pil.Launcher(componentArgs, builder);
            
            % File extension for shared libraries (e.g. .dll on Windows)
            [~, ~, sharedLibExt] = coder.BuildConfig.getStdLibInfo;
            %sharedLibExt = system_dependent('GetSharedLibExt');

            % Evaluate name of the rtIOStream shared library
            rtiostreamLib = ['libmwrtiostreamtcpip' sharedLibExt];
            
            hostCommunicator = rtw.connectivity.RtIOStreamHostCommunicator(...
                componentArgs, ...
                launcher, ...
                rtiostreamLib);
            
            % For some targets it may be necessary to set a timeout value
            % for initial setup of the communications channel. For example,
            % the target processor may take a few seconds before it is
            % ready to open its side of the communications channel. If a
            % non-zero timeout value is set then the communicator will
            % repeatedly try to open the communications channel until the
            % timeout value is reached.
            hostCommunicator.setInitCommsTimeout(30); 
            
            % Configure a timeout period for reading of data by the host 
            % from the target. If no data is received with the specified 
            % period an error will be thrown.
            timeoutReadDataSecs = 60;
            hostCommunicator.setTimeoutRecvSecs(timeoutReadDataSecs);


            % Choose a port number for TCP (for both host and target)
            if usejava('jvm')
                % Find a free port
                tempSocket = java.net.ServerSocket(0);
                portNumStr = num2str(tempSocket.getLocalPort);
                tempSocket.close;
            else
                % Resort to a hard-coded port
                portNumStr = '14646';
            end
            
            % Specify additional arguments when starting the           
            % executable (this configures the target-side of the       
            % communications channel)                                  
            launcher.setArgString(['-port ' portNumStr ' -blocking 1'])

            % Custom arguments that will be passed to the              
            % rtIOStreamOpen function in the rtIOStream shared        
            % library (this configures the host-side of the           
            % communications channel) 
            serverhostname = '127.0.0.1';                                 
            rtIOStreamOpenArgs = {...                                  
                '-hostname', serverhostname, ...                         
                '-client', '1', ...                                    
                '-blocking', '1', ...                                  
                '-port',portNumStr,...                                 
                };                                                     
                      
            hostCommunicator.setOpenRtIOStreamArgList(...          
                rtIOStreamOpenArgs); 

            
            % call super class constructor to register components
            this@rtw.connectivity.Config(componentArgs,...
                                         builder,...
                                         launcher,...
                                         hostCommunicator);
            
            % Optionally, you can register a hardware-specific timer. Registering a timer
            % enables the code execution profiling feature. In this example
            % implementation, we use a timer for the host platform.
            %timer = coder.profile.crlHostTimer();
            %this.setTimer(timer);
            
        end
    end
end

