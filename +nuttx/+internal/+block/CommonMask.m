classdef CommonMask 
    %This class is for internal use only. It may be removed in the future.
    
    %CommonMask - Base class with shared code for working with Simulink block masks
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    
    properties (Constant, Abstract)
        %MaskType - Type of block mask
        %   Retrieve is with get_param(gcb, 'MaskType')
        MaskType
    end
    
    properties (Constant, Abstract)
        %MaskParamIndex - Struct specifying index of various parameters
        %   associated with the block mask, for example: TopicEdit 
        MaskParamIndex
        
        %MaskDlgIndex - Struct specifying index of various widgets in the
        %   block mask  that *aren't* parameters, for example: buttons for
        %   topic selection
        MaskDlgIndex
        
        % SysObjBlockName - Name of System Object block inside the 
        %   subsystem (or '' if there is no system object block)
        SysObjBlockName
        
    end
    
    methods(Static, Abstract)
        dispatch(methodName, varargin)
    end
    
    methods(Abstract)
        out = getDropDownVisiblility(~);
    end
    
    methods(Static)
        %% Utilities
        function out = isLibraryBlock(block)
            out = strcmpi(get_param(bdroot(block), 'BlockDiagramType'), 'library');
        end
    end
    
    methods (Abstract)        
        updateSubsystem(obj, block)
        %updateSubsystem Update subsystem when configuration changes are made
        %   For example, this should be called when users make changes on
        %   the block mask, or if they call get_param and set_param.
    end
              
    methods
        %% Mask Initialization
        % This counts as a callback. It is invoked when the user: 
		% * Changes the value of a mask parameter by using the block dialog box or�set_param.
        % * Changes any of the parameters that define the mask
        % * Causes the icon to be redrawn
        % * Copies the block
        %
        % Mask initialization is invoked after the individual parameter
        % callbacks
        
        function maskInitialize(obj, block) %#ok<INUSD>
            % This is invoked after the callbacks
        end        
        
    end    
end
