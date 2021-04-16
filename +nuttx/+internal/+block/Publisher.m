classdef Publisher < matlab.System & ...
        matlab.system.mixin.Propagates & ...
        matlab.system.mixin.SampleTime & ...
        coder.ExternalDependency

    %This class is for internal use only. It may be removed in the future.

    %Publish messages to a uORB network
    %
    %   H = nuttx.internal.block.Publisher creates a system
    %   object, H, that advertises a topic to a nuttx network and publishes
    %   messages to that topic.
    %
    %   This system object is intended for use with the MATLAB System
    %   block.
    %
    %   See also nuttx.internal.block.Subscriber

    %   Copyright 2018-2020 The MathWorks, Inc.

    %#codegen

    
    properties (Nontunable)
        %uORBTopic Topic to publish to
        %  This system object will use uORBTopic as specified in both
        %  simulation and code generation.
        uORBTopic = 'sensor_'

        %MessageQueueLen Length of advertise queue
        MessageQueueLen = 1

        uORBTopicInstance = 'sensor_'
    end
    
    % The following should ideally not show up in the MATLAB System block
    % dialog. However, setting them as 'Hidden' will prevent them from
    % being accessible via set_param & get_param.
    properties(Nontunable)
        %SLBusName Simulink Bus Name for message type
        %   Not really used; only maintained for symmetry with Subscriber
        SLBusName = ''
    end

    properties (Nontunable,Access=private)
        ConnectHandle
        uORBIOHandle
    end
    
    properties(Constant,Access=private)
        % Name of header file with declarations for variables and types
        % referred to in code emitted by setupImpl and stepImpl.
        HeaderFile = nuttx.internal.cgen.Constants.uORBWriteCode.HeaderFile
    end
    
    properties (Access = ...
                {?nuttx.internal.block.Subscriber, ...
                ?matlab.unittest.TestCase})

        % event File handler
        orbAdvertiseObj

        orbMetadataObj
    end

    methods
        % Constructor
        function obj = Publisher(varargin)
            % Enable code to be generated even this file is p-coded
            coder.allowpcode('plain');

            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end

        function set.uORBTopic(obj, val)
            validateattributes(val, {'char'}, {'nonempty'}, '', 'uORBTopic');
            obj.uORBTopic = val;
        end

        function set.uORBTopicInstance(obj, val)
            validateattributes(val, {'char'}, {'nonempty'}, '', 'uORBTopicInstance');
            obj.uORBTopicInstance = val;
        end

        function set.MessageQueueLen(obj, val)
            validateattributes(val, ...
                               {'numeric'}, {'positive', 'integer', 'scalar'}, '', 'MessageQueueLen');
            obj.MessageQueueLen = int32(val);
        end

        function set.SLBusName(obj, val)
            validateattributes(val, {'char'}, {}, '', 'SLBusName');
            obj.SLBusName = val;
        end

    end
    
    methods (Access=protected)

        function sts = getSampleTimeImpl(obj)
                % Enable this system object to inherit constant ('inf') sample times
                sts = createSampleTime(obj, 'Type', 'Inherited', 'Allow', 'Constant');
            end

        function setupImpl(obj) %#ok<MANU>
                    % setupImpl is called when model is being initialized at the
        % start of a simulation

        if coder.target('MATLAB')
            %Connected IO
            % if matlabshared.svd.internal.isSimulinkIoEnabled
            %     try
            %         %create handles required for Connected IO
            %         %handle class to manage deployment and connection to IO server
            %         obj.ConnectHandle = matlabshared.ioclient.DeployAndConnectHandle;
            %         %uORB IO wrapper class to read and write data
            %         obj.ConnectHandle.getConnectedIOClient;
            %         obj.uORBIOHandle = nuttx.internal.ConnectedIO.uORBIO;
            %         %get uORBID - unique numeric value correspond to individual uORB
            %         %message
            %         uORBID = uint8(nuttx.internal.ConnectedIO.uORBMsgMap.(obj.uORBTopicInstance));
            %         %uORB init
            %         [obj.orbMetadataObj,obj.orbAdvertiseObj] = uORBWriteInitialize (obj.uORBIOHandle, obj.ConnectHandle.IoProtocol, uORBID, obj.MessageQueueLen,busstruct);
            %     catch exception
            %         %remove the IO client object in case of error
            %         obj.ConnectHandle.deleteConnectedIOClient();
            %         throw(exception);
            %     end
            % end
        elseif coder.target('RtwForRapid')
            % Rapid Accelerator. In this mode, coder.target('Rtw')
            % returns true as well, so it is important to check for
            % 'RtwForRapid' before checking for 'Rtw'
            coder.internal.errorIf(true, 'nuttx:sysobj:PublisherRapidAccelNotSupported');

        elseif coder.target('Rtw')
            coder.cinclude(obj.HeaderFile);
            nuttx.internal.cgen.Constants.includeCommonHeaders();

            obj.orbAdvertiseObj = coder.opaque('orb_advert_t');
            addr = coder.const(['ORB_ID(' obj.uORBTopicInstance ')']);

            obj.orbMetadataObj = coder.opaque('orb_metadata_t *',addr);

            % Evaluate the initialize function.
            coder.ceval('uORB_write_initialize', ...
                        obj.orbMetadataObj, ...
                        coder.wref(obj.orbAdvertiseObj), ...
                        coder.rref(busstruct), ...
                        obj.MessageQueueLen);

        elseif  coder.target('Sfun')
            % 'Sfun'  - SimThruCodeGen target
            % Do nothing. MATLAB System block first does a pre-codegen
            % compile with 'Sfun' target, & then does the "proper"
            % codegen compile with Rtw or RtwForRapid, as appropriate.

        else
            % 'RtwForSim' - ModelReference SIM target
            % 'MEX', 'HDL', 'Custom' - Not applicable to MATLAB System block
            coder.internal.errorIf(true, 'nuttx:sysobj:UnsupportedCodegenMode');
        end
        end
        
        function message = stepImpl(obj)   %#ok<MANU>
            if coder.target('MATLAB')
                %Connected I/O
                % if matlabshared.svd.internal.isSimulinkIoEnabled
                %     try
                %         uORBWriteMessage(obj.uORBIOHandle, obj.ConnectHandle.IoProtocol, obj.orbMetadataObj, ...
                %                          obj.orbAdvertiseObj, busstruct);
                %     catch exception
                %         %call releaseImpl case of error
                %         releaseImpl(obj)
                %         throw(exception);
                %     end
                % end
            elseif coder.target('Rtw')
                % The datatype of msg will be derived from the input to the block
                coder.ceval('uORB_write_step', ...
                            obj.orbMetadataObj, ...
                            coder.rref(obj.orbAdvertiseObj), ...
                            coder.rref(busstruct));
            end
        end
        
        function releaseImpl(obj) %#ok<MANU>
            if coder.target('MATLAB')
                %Connected I/O
                % if matlabshared.svd.internal.isSimulinkIoEnabled
                %     obj.ConnectHandle.deleteConnectedIOClient();
                %     uORBWriteRelease (obj.uORBIOHandle, obj.ConnectHandle.IoProtocol, obj.orbAdvertiseObj);
                % end
            elseif coder.target('Rtw')
                coder.ceval('uORB_write_terminate', coder.rref(obj.orbAdvertiseObj));
            end
        end
    end
    
    methods (Access=protected)
        %% Define output properties
        function num = getNumInputsImpl(~)
            num = 1;
        end
        
        function num = getNumOutputsImpl(~)
            num = 0;
        end
         
        function flag = isInactivePropertyImpl(~,propertyName)
            flag = true;

            if strcmp(propertyName,'uORBTopic')
                flag = false;
            end
            if strcmp(propertyName,'uORBTopicInstance')
                flag = false;
            end

            if strcmp(propertyName,'MessageQueueLen')
                flag = false;
            end
        end

    end
    
    methods (Static, Access=protected)
        %% Simulink customization functions
        function header = getHeaderImpl
            header = matlab.system.display.Header(mfilename('class') ,'ShowSourceLink',false);
        end

        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function flag = showSimulateUsingImpl
            % Return false if simulation mode hidden in System block dialog
            flag = false;
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'Nuttx uORB Read and Write';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                srcDir = fullfile(fileparts(mfilename('fullpath')),'src'); %#ok<NASGU>
                includeDir = fullfile(fileparts(mfilename('fullpath')),'include');
                addIncludePaths(buildInfo,includeDir);
                % Use the following API's to add include files, sources and
                % linker flags
                %addIncludeFiles(buildInfo,'uorbtopic.h',includeDir);
                %addSourceFiles(buildInfo,'uorbtopic.c',srcDir);
                %addLinkFlags(buildInfo,{'-lSource'});
                %addLinkObjects(buildInfo,'sourcelib.a',srcDir);
                %addCompileFlags(buildInfo,{'-D_DEBUG=1'});
                %addDefines(buildInfo,'MY_DEFINE_1')
            end
        end
    end
end
