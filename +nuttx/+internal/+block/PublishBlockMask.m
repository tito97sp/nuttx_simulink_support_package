classdef PublishBlockMask < nuttx.internal.block.CommonMessageMask
    %This class is for internal use only. It may be removed in the future.
    
    %PublishBlockMask - Block mask callbacks for Publish block
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    
    properties (Constant)
        %MaskType - Type of block mask
        %   Retrieve is with get_param(gcb, 'MaskType')
        MaskType = 'uORB Publish'
        
        MaskParamIndex = struct( ...
            'TopicEdit', 1 ...
            );
        
        MaskDlgIndex = struct( ...
            'TopicSelect', [2 1 2] ...  % Tab Container > "Main" tab > Topic Select Button
            );
        
        SysObjBlockName = 'SinkBlock';        
    end
    
    methods
        
        function updateSubsystem(obj, block)
            sysobj_block = [block '/' obj.SysObjBlockName];
            sigspec_block = [block '/SignalSpecification'];
            
            uORBMsgType = get_param(block, 'uORBTopic');
            uORBMsgTypeInstance = get_param(block, 'selectInstance');

            [busDataType, slBusName] = nuttx.internal.bus.Util.uORBMsgTypeToDataTypeStr(uORBMsgType, bdroot(block));            
           
            set_param(sysobj_block, 'SLBusName', slBusName);
            set_param(sysobj_block, 'uORBTopic', uORBMsgType);
            set_param(sigspec_block, 'OutDataTypeStr', busDataType);                        
            
            handle = obj.getDropDownHandle(block);
            if isequal(handle.Visible, 'on')
                set_param(sysobj_block, 'uORBTopicInstance', uORBMsgTypeInstance);
            else
                set_param(sysobj_block, 'uORBTopicInstance', uORBMsgType);
            end
        end
        
        function out = getDropDownVisiblility(~)
            out = 'on';
        end
        
    end    
        
    methods(Static)
        
        function dispatch(methodName, varargin)
            obj = nuttx.internal.block.PublishBlockMask();
            obj.(methodName)(varargin{:});
        end
        
    end        
end
