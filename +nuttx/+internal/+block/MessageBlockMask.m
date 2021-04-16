classdef MessageBlockMask < nuttx.internal.block.CommonMessageMask
    %This class is for internal use only. It may be removed in the future.
    
    %MessageBlockMask - Block mask callbacks for "uORB Message" block
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    
    properties (Constant)
        %MaskType - Type of block mask
        %   Retrieve is with get_param(gcb, 'MaskType')
        MaskType = 'Nuttx uORB Message'
        
        MaskParamIndex = struct( ...
            'topicEdit', 1)
        
        MaskDlgIndex = struct( ...
            'topicSelect', [2 3] ... % Parameters Container > Msg Select Button
            )
        
        SysObjBlockName = ''  % No system object block
    end
    
    methods
        function updateSubsystem(~, block)
            %updateSubsystem Update the constant block in subsystem
            
            topicType = get_param(block, 'uORBTopic');
            constantBlock = [block '/Constant'];
            
            busDataType = nuttx.internal.bus.Util.uORBMsgTypeToDataTypeStr(topicType, bdroot(block));
            set_param(constantBlock, 'OutDataTypeStr', busDataType);
        end
        
        function out = getDropDownVisiblility(~)
            out = 'off';
        end
        
    end
    
    methods (Static)       
        
        function dispatch(methodName, varargin)
            obj = nuttx.internal.block.MessageBlockMask();
            obj.(methodName)(varargin{:});
        end
        
    end
end
