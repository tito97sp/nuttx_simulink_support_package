classdef (Abstract) CommonMessageMask < nuttx.internal.block.CommonMask
%CommonMessageMask Common base class for uORB message publishers and
%subscribers

%   Copyright 2018-2020 The MathWorks, Inc.

    methods
        %% ModelCloseFcn
        function modelCloseFcn(~, block)
        %modelCloseFcn Called when the model is closed

            nuttx.internal.bus.clearBusesOnModelClose(block);
        end
    end

    methods
        %% Block InitFcns

        % Callbacks for individual params are invoked when:
        % * User opens a mask dialog
        % * User modifies a param value and changes focus
        % * User modifies a param value and selects OK or Apply
        % * The model is updated (user presses Ctrl+D or simulates the model)

        function constantBlkInitFcn(obj, constantBlk)                     %#ok<INUSL>
            block = get_param(constantBlk, 'parent');
            uORBMsgType = get_param(block, 'uORBTopic');
            nuttx.internal.bus.Util.createBusIfNeeded(uORBMsgType, bdroot(constantBlk));
        end

        function sysobjInitFcn(obj, sysobjBlock) %#ok<INUSL>
            uORBMsgType = get_param(sysobjBlock, 'uORBTopic');
            expectedBusName = nuttx.internal.bus.Util.uORBMsgTypeToBusName(uORBMsgType, bdroot(sysobjBlock));

            currentBusName = get_param(sysobjBlock, 'SLBusName');
            if ~strcmp(currentBusName, expectedBusName)
                % Do not mark the model dirty when the Simulink bus name
                % is updated on the underlying mask of Simulink uORB system
                % object blocks.
                % All changes to model is ignored when this
                % "preserveDirty" variable is in Scope, hence this only
                % encompasses the set_param call in this if-else section.
                preserveDirty = Simulink.PreserveDirtyFlag(bdroot(sysobjBlock),'blockDiagram');  %#ok<NASGU>
                set_param(sysobjBlock, 'SLBusName', expectedBusName);
            end
        end
    end

    %%
    methods
        %% Callbacks
        % Callbacks for individual params are invoked when the user:
        % * Opens a mask dialog
        % * Modifies a param value and changes focus
        % * Modifies a param value and selects OK or Apply
        % * Updates the model (presses Ctrl+D or simulates the model)
        %
        % Note - these are **not** invoked when user does a SET_PARAM
        function blockingModeSelect(obj, block)
            maskValues = get_param(block, 'MaskValues');
            maskVisibilities = get_param(block, 'MaskVisibilities');
            maskEnables = get_param(gcb,'MaskEnables');

            if isequal(maskValues{obj.MaskParamIndex.BlockingMode}, 'on')
                % Show Blocking Timeout Edit Field
                maskVisibilities{obj.MaskParamIndex.BlockingTimeout} = 'on';
            else
                % Show Blocking Timeout Edit Field
                maskVisibilities{obj.MaskParamIndex.BlockingTimeout} = 'off';
            end

            set_param(gcb,'MaskEnables', maskEnables);
            set_param(gcb,'MaskVisibilities', maskVisibilities);

        end

        function topicEdit(obj, block)
            sysobj_block = [block '/' obj.SysObjBlockName];
            curValue = get_param(sysobj_block, 'uORBTopic');
            newValue = get_param(block, 'uORBTopic');
            if ~nuttx.internal.bus.Util.isValidTopicName(newValue)
                set_param(block, 'uORBTopic', curValue);
                nuttx.internal.util.CommonUtility.localizedError('nuttx:blockmask:InvalidTopicName', newValue);
            end


            file_path = nuttx.internal.util.CommonUtility.getNuttxConfigDir ;
            obj.fillDropDown(block, file_path,[newValue '.msg'], newValue);


            nuttx.internal.bus.Util.createBusIfNeeded(newValue, bdroot(block));
            obj.updateSubsystem(block);
        end

        function topicSelect(obj, block)
            try
                file_path = nuttx.internal.util.CommonUtility.getNuttxConfigDir;
                [MsgFile_Name_ext,~,~] = uigetfile([file_path,filesep,'*.msg']);

                if (MsgFile_Name_ext~=0)
                    [~, MsgFile_Name]=fileparts(MsgFile_Name_ext);
                    set_param(block,'uORBTopic', MsgFile_Name );
                    obj.fillDropDown(block, file_path, MsgFile_Name_ext, MsgFile_Name);
                end

            catch ME
                % Send error to Simulink diagnostic viewer rather than a
                % DDG dialog.
                % NOTE: This does NOT stop execution.
                reportAsError(MSLDiagnostic(ME));
            end
        end

        function handle = getDropDownHandle(~, block)
            mobj = Simulink.Mask.get(block);
            names = {mobj.Parameters.Name};
            index = strcmp(names, 'selectInstance');
            handle =  mobj.Parameters(index);
        end

        function fillDropDown(obj,block, file_path,MsgFile_Name_ext, MsgFile_Name)
            topicInstances =  nuttx.internal.bus.Util.parseFileForUORBInstance(fullfile(file_path,MsgFile_Name_ext));
            handle = obj.getDropDownHandle(block);
            if ~isempty(topicInstances)
                handle.TypeOptions = topicInstances;
                handle.Visible = obj.getDropDownVisiblility();
            else
                handle.TypeOptions = {MsgFile_Name};
                handle.Value = MsgFile_Name;
                handle.Visible = 'off';
            end
        end

    end
end
