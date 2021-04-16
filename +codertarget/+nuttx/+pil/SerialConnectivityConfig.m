classdef SerialConnectivityConfig < rtw.connectivity.Config
    %SERIALCONNECTIVITYCONFIG
    %
    %
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    methods
        % Constructor
        function this = SerialConnectivityConfig(componentArgs)
            % An executable framework specifies additional source files and
            % libraries required for building the PIL executable
            componentArgs.CoderAssumptionsEnabled = false;
            targetApplicationFramework = ...
                codertarget.pixhawk.pil.SerialTargetApplicationFramework(componentArgs);
            % Create an instance of MakefileBuilder; this works in
            % conjunction with your template makefile to build the PIL
            % executable
            builder = codertarget.pixhawk.pil.PX4MakefileBuilder(componentArgs, ...
                targetApplicationFramework, ...
                '.px4');
            
            % Launcher
            launcher = codertarget.pixhawk.pil.SerialLauncher(componentArgs, builder);
            % Host side rtiostream communication
            sharedLibExt = system_dependent('GetSharedLibExt');
            rtiostreamLib = ['libmwrtiostreamserial' sharedLibExt];
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
            hostCommunicator.setInitCommsTimeout(0);
            
            % Configure a timeout period for reading of data by the host
            % from the target. If no data is received with the specified
            % period an error will be thrown.
            hostCommunicator.setTimeoutRecvSecs(10);
            
            % Retrieve COM port from config set
            hCS = componentArgs.getConfigInterface.getConfig;
            COMPort = codertarget.pixhawk.internal.getPILSerialPortName(hCS);
            [baudRate,~] = codertarget.pixhawk.internal.getPILInfo(hCS);
            if isunix
                %supported baud rates for linux platform
                baudRateAvailable = [ 50, 75, 110, 134, 150 ...
                    200, 300, 600, 1200, 1800, 2400, 4800, 9600 ...
                    19200, 38400, 57600, 115200, 230400];
                
                %if the current baud rate is not supported error out
                if ~ismember(str2double(baudRate), baudRateAvailable)
                    error(message('px4:general:BaudRateNotSupported', baudRate, num2str(baudRateAvailable)).getString);
                end
            end
            
            fprintf('### COM port: %s\n', COMPort);
            fprintf('### Baud rate: %s\n', baudRate)
            % Set serial host port settings
            rtIOStreamOpenArgs = {...
                '-baud', num2str(baudRate), ...
                '-port', COMPort, ...
                };
            
            hostCommunicator.setOpenRtIOStreamArgList(...
                rtIOStreamOpenArgs);
            
            % Call super class constructor to register components
            this@rtw.connectivity.Config(componentArgs,...
                builder,...
                launcher,...
                hostCommunicator);
            
            % Register timer functions
            coderTargetData = componentArgs.getParam('CoderTargetData');
            if ~isempty(coderTargetData.Clocking.cpuClockRateMHz)
                clockRate = 1e6 * str2double(coderTargetData.Clocking.cpuClockRateMHz);
            else
                %For 'PX4 Pixhawk Series' the default clocking value is empty and
                %if profiling is on the user should be notified to enter a valid clock frequency for the board.
                if isequal(get_param(hCS,'CodeExecutionProfiling'),'on')
                    error(message('px4:general:ClockEmpty'));
                else
                    clockRate = 1e6 * 180; %default value 180MHz
                end
            end
            timer = codertarget.pixhawk.pil.Timer(clockRate);
            this.setTimer(timer);
            
        end
    end
end
