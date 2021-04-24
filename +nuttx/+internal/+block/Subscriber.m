classdef Subscriber < matlab.System & ...
        matlab.system.mixin.Propagates & ...
        coder.ExternalDependency & ...
        matlab.system.mixin.SampleTime
    
    %This class is for internal use only. It may be removed in the future.
    
    %Subscribe to a topic on a PX4 uORB network
    %
    %   H = px4.internal.block.Subscriber creates a system
    %   object, H, that subscribes to a topic on a uORB network and
    %   receives messages on that topic.
    %
    %   This system object is intended for use with the MATLAB System
    %   block.
    %
    %   See also px4.internal.block.Publisher
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    %#codegen
    
    properties (Nontunable)
        %uORBTopic Topic to subscribe to
        %  This system object will use uORBTopic as specified in both
        %  simulation and code generation.
        uORBTopic = 'sensor_'
        
        uORBTopicInstance = 'sensor_'
    end
    
    % The following should ideally not show up in the MATLAB System block
    % dialog. However, setting them as 'Hidden' will prevent them from
    % being accessible via set_param & get_param.
    %
    properties(Nontunable)
        %SLBusName Simulink Bus Name for message type
        SLBusName = 'px4_Bus'
    end
    properties (Nontunable,Access=private)
        ConnectHandle
        uORBIOHandle
    end
    properties (Nontunable)
        %Sample time
        SampleTime = 0.1;
    end
    
    % Properties in Advanced Tab
    properties(Nontunable, Logical)
        %Wait until data received
        BlockingMode = false;
    end
    
    properties(Nontunable)
        % Timeout in seconds
        BlockTimeout = 0.1;
    end
    
    properties(Constant,Access=private)
        % Name of header file with declarations for variables and types
        % referred to in code emitted by setupImpl and stepImpl.
        HeaderFile = px4.internal.cgen.Constants.uORBReadCode.HeaderFile
    end
    
    properties (Access = ...
            {?px4.internal.block.Subscriber, ...
            ?matlab.unittest.TestCase})
        %SampleTimeHandler - Object for validating sample time settings
        SampleTimeHandler
        
        % event handler
        eventStructObj
        
        orbMetadataObj
    end
    
    methods
        function obj = Subscriber(varargin)
            % Enable code to be generated even this file is p-coded
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
            
            % Initialize sample time validation object
            obj.SampleTimeHandler = px4.internal.block.SampleTimeImpl;
        end
        
        function set.uORBTopic(obj, val)
            validateattributes(val, {'char'}, {'nonempty'}, '', 'uORBTopic');
            obj.uORBTopic = val;
        end
        
        function set.SLBusName(obj, val)
            validateattributes(val, {'char'}, {'nonempty'}, '', 'SLBusName');
            obj.SLBusName = val;
        end
        
        function set.uORBTopicInstance(obj, val)
            validateattributes(val, {'char'}, {'nonempty'}, '', 'uORBTopicInstance');
            obj.uORBTopicInstance = val;
        end
        
        function set.BlockTimeout(obj, val)
            classes = {'numeric'};
            % Limiting blocking timeout to 2^32/1000 i.e. max of unsigned long /1000 milli seconds.
            attributes = {'nonempty','nonnan','real','nonnegative','nonzero','scalar','<=',(2^32*0.001)};
            paramName = 'Blocking Timeout in seconds';
            validateattributes(val,classes,attributes,'',paramName);
            obj.BlockTimeout = val;
        end
        
        function set.SampleTime(obj, sampleTime)
            %set.SampleTime Validate sample time specified by user
            obj.SampleTime = obj.SampleTimeHandler.validate(sampleTime);  %#ok<MCSUP>
        end
        
    end
    
    methods (Access = protected)
        %% Inherited from matlab.system.mixin.SampleTime
        function sts = getSampleTimeImpl(obj)
            %getSampleTimeImpl Return sample time specification
            
            sts = obj.SampleTimeHandler.createSampleTimeSpec();
        end
        
    end
    
    methods (Access = protected)
        
        function num = getNumInputsImpl(~)
            num = 1;
        end
        
        function num = getNumOutputsImpl(~)
            num = 2;
        end
        
        function varargout = getOutputSizeImpl(~)
            varargout = {[1 1], [1 1]};
        end
        
        function varargout = isOutputFixedSizeImpl(~)
            varargout =  {true, true};
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            varargout =  {'logical', obj.SLBusName};
        end
        
        function varargout = isOutputComplexImpl(~)
            varargout = {false, false};
        end
        
        function flag = isInactivePropertyImpl(~,propertyName)
            flag = true;
            
            if strcmp(propertyName,'uORBTopic')
                flag = false;
            end
            if strcmp(propertyName,'uORBTopicInstance')
                flag = false;
            end
            if strcmp(propertyName,'SampleTime')
                flag = false;
            end
            if strcmp(propertyName,'BlockingMode')
                flag = false;
            end
            if strcmp(propertyName,'BlockTimeout')
                flag = false;
            end
        end
        
    end
    
    methods (Access = protected)
        %% Common functions
        function setupImpl(obj)
            % setupImpl is called when model is being initialized at the
            % start of a simulation
            
            if coder.target('MATLAB')
                %ConnectedI/O
                if matlabshared.svd.internal.isSimulinkIoEnabled
                    try
                        %create handles required for Connected IO
                        %handle class to manage deployment and connection to IO server
                        obj.ConnectHandle = matlabshared.ioclient.DeployAndConnectHandle;
                        obj.ConnectHandle.getConnectedIOClient;
                        %uORB IO wrapper class to read and write data
                        obj.uORBIOHandle = px4.internal.ConnectedIO.uORBIO;
                        %get uORBID - unique numeric value correspond to individual uORB
                        %message
                        uORBID = uint8(px4.internal.ConnectedIO.uORBMsgMap.(obj.uORBTopicInstance));
                        %uORB init
                        [obj.orbMetadataObj,obj.eventStructObj] = uORBReadInitialize (obj.uORBIOHandle, obj.ConnectHandle.IoProtocol, uORBID);
                    catch exception
                        %remove the IO client object in case of error
                        obj.ConnectHandle.deleteConnectedIOClient();
                        throw(exception);
                    end
                end
            elseif coder.target('RtwForRapid')
                % Rapid Accelerator. In this mode, coder.target('Rtw')
                % returns true as well, so it is important to check for
                % 'RtwForRapid' before checking for 'Rtw'
                coder.internal.errorIf(true, 'px4:sysobj:SubscriberRapidAccelNotSupported');
                
            elseif coder.target('Rtw')
                coder.cinclude(obj.HeaderFile);
                px4.internal.cgen.Constants.includeCommonHeaders();
                
                obj.eventStructObj = coder.opaque('pollfd_t');
                addr = coder.const(['ORB_ID(' obj.uORBTopicInstance ')']);
                
                obj.orbMetadataObj = coder.opaque('orb_metadata_t *',addr);
                
                % Evaluate the initialize function.
                coder.ceval('uORB_read_initialize', ...
                    obj.orbMetadataObj, ...
                    coder.wref(obj.eventStructObj) );
                
            elseif  coder.target('Sfun')
                % 'Sfun'  - SimThruCodeGen target
                % Do nothing. MATLAB System block first does a pre-codegen
                % compile with 'Sfun' target, & then does the "proper"
                % codegen compile with Rtw or RtwForRapid, as appropriate.
                
            else
                % 'RtwForSim' - ModelReference SIM target
                % 'MEX', 'HDL', 'Custom' - Not applicable to MATLAB System block
                coder.internal.errorIf(true, 'px4:sysobj:UnsupportedCodegenMode');
            end
        end
        
        
        %%
        function [isNewData, msg] = stepImpl(obj, busstruct)
            % <busstruct> is a blank (empty) bus structure. It is necessary
            % since there is no convenient way to create the (arbitrarily
            % complex and nested) bus structure.
            
            isNewData = coder.nullcopy(false);
            msg = busstruct ;
            
            % If isNewData is true, msg holds the new message (SL bus layout).
            %
            % If isNewData is false, msg is unmodified from busstruct
            %   (i.e., it is an empty bus). The rationale is that we want
            %   to avoid overhead of converting a message to bus.
            %   In this case, MATLAB system block output needs to be
            %   latched, so that the user sees the most-recent-valid
            %   message. (This latching could have been done inside
            %   get_latest_msg, but it is better to let Simulink do it, as
            %   that allows it to generate more optimized code).
            
            if coder.target('MATLAB')
                %Connected I/O
                if matlabshared.svd.internal.isSimulinkIoEnabled
                    try
                        [msg,isNewData] = uORBReadMessage (obj.uORBIOHandle, obj.ConnectHandle.IoProtocol, obj.orbMetadataObj, ...
                            obj.eventStructObj, obj.BlockingMode, (obj.BlockTimeout)*1000,busstruct);
                        isNewData = boolean(isNewData);
                    catch exception
                        %call releaseImpl case of error
                        releaseImpl(obj)
                        throw(exception);
                    end
                end
            elseif coder.target('Rtw')
                isBlocking = obj.BlockingMode;
                msg = coder.nullcopy(busstruct);
                isNewData = coder.ceval('uORB_read_step', ...
                    obj.orbMetadataObj, ...
                    coder.rref(obj.eventStructObj), ...
                    coder.wref(msg), ...
                    isBlocking, ...
                    (obj.BlockTimeout)*1000); % Blocking timeout time in milliseconds
            end
            
        end
        
        %%
        function releaseImpl(obj)
            
            if coder.target('MATLAB')
                %Connected I/O
                if matlabshared.svd.internal.isSimulinkIoEnabled
                    obj.ConnectHandle.deleteConnectedIOClient();
                    uORBReadRelease (obj.uORBIOHandle, obj.ConnectHandle.IoProtocol, obj.eventStructObj);
                end
            elseif coder.target('Rtw')
                coder.ceval('uORB_read_terminate', coder.rref(obj.eventStructObj));
            end
        end
        
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'PX4 uORB Read and Write';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            % Update the build-time buildInfo
            if context.isCodeGenTarget('rtw')
                spkgRootDir = codertarget.pixhawk.internal.getSpPkgRootDir ;
                % Include Paths
                addIncludePaths(buildInfo, fullfile(spkgRootDir, 'include'));
                % Source Files
                systemTargetFile = get_param(buildInfo.ModelName,'SystemTargetFile');
                if isequal(systemTargetFile,'ert.tlc')
                    % Add the following when not in rapid-accel simulation
                    addSourcePaths(buildInfo, fullfile(spkgRootDir, 'src'));
                    addSourceFiles(buildInfo, 'MW_uORB_Read.cpp', fullfile(spkgRootDir, 'src'));
                end
            end
            
        end
    end
    
    methods(Static, Access = protected)
        %% Simulink customization functions
        function header = getHeaderImpl
            header = matlab.system.display.Header(mfilename('class') ,'ShowSourceLink',false);
        end
        
        function simMode = getSimulateUsingImpl
            % Return only allowed simulation mode in System block dialog
            simMode = "Interpreted execution";
        end
        
        function flag = showSimulateUsingImpl
            % Return false if simulation mode hidden in System block dialog
            flag = false;
        end
        
    end
    
end
