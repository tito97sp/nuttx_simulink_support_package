classdef SubscribeBlockMask < nuttx.internal.block.CommonMessageMask
    %This class is for internal use only. It may be removed in the future.
    
    %SubscribeBlockMask - Block mask callbacks for Subscribe block
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    
    properties (Constant)
        %MaskType - Type of block mask
        %   Retrieve is with get_param(gcb, 'MaskType')
        MaskType = 'Nuttx uORB Read'
        
        MaskParamIndex = struct( ...
            'TopicEdit', 1, ...
            'BlockingMode', 4, ...
            'BlockingTimeout', 5 ...
            );
        
        MaskDlgIndex = struct( ...
            'TopicSelect', [2 1 2] ...  % Tab Container > "Main" tab > Topic Select Button
            );
    
        SysObjBlockName = 'SourceBlock';
    end

    methods
        
        function updateSubsystem(obj, block) 
            sysobj_block = [block '/' obj.SysObjBlockName];
            const_block = [block '/Constant'];
            
            uORBMsgType = get_param(block, 'uORBTopic');
            uORBMsgTypeInstance = get_param(block, 'selectInstance');

            [busDataType, slBusName] = nuttx.internal.bus.Util.uORBMsgTypeToDataTypeStr(uORBMsgType, bdroot(block));
            
            set_param(sysobj_block, 'SLBusName', slBusName);
            set_param(sysobj_block, 'uORBTopic', uORBMsgType);
            set_param(const_block,'OutDataTypeStr', busDataType);
            
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
            obj = nuttx.internal.block.SubscribeBlockMask();
            obj.(methodName)(varargin{:});
        end
        
    end    
end
