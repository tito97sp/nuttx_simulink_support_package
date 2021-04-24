classdef NuttxModelInfo
%This class is for internal use only. It may be removed in the future.

%  NuttxModelInfo is a utility class that encapsulates information about
%  Nuttx blocks in a Simulink model.
%
%  See also: cgen.NuttxBlockInfo

%   Copyright 2018-2020 The MathWorks, Inc.

    properties(SetAccess=private)
        %Model - Name of Simulink model
        Model

        %PubSubBlocks - List of Nuttx publish, subscribe, and message blocks in the model
        PubSubBlocks

        % List of top-level message types in the model (i.e., the
        % message types used in Nuttx blocks that handle buses).
        TopicTypes

        % Info about Subscribe blocks in model (list of cgen.NuttxMessageBlockInfo objects)
        SubscriberList = nuttx.internal.cgen.NuttxMessageBlockInfo.empty

        % Info about Publish blocks in model (list of cgen.NuttxMessageBlockInfo objects)
        PublisherList = nuttx.internal.cgen.NuttxMessageBlockInfo.empty

    end

    %%
    methods
        function obj= NuttxModelInfo(model)
            obj.Model = model;

            [obj.TopicTypes, obj.PubSubBlocks] = ...
                nuttx.internal.cgen.Util.getNuttxuORBBlocksInModel(model);

        end

        function topicTypes = topicTypesInModel(obj)
        %topicTypesInModel Returns the unique top-level message types in model
            topicTypes = unique(obj.TopicTypes);
        end
    end

    %%
    methods(Access = private)

        function obj = getInfoFromNuttxBlocks(obj)

        % Get more information about subscribers and publishers
            [obj.SubscriberList, obj.PublisherList] = ...
                obj.getInfoFromPubSubBlocks;

        end

        function [subList, pubList] = getInfoFromPubSubBlocks(obj)
        %getInfoFromPubSubBlocks Iterate over blocks and extract information from pub/sub blocks

            subList = [];
            pubList = [];

            for i=1:numel(obj.PubSubBlocks)
                block = obj.PubSubBlocks{i};
                maskType = get_param(block, 'MaskType');
                if strcmpi(maskType,nuttx.internal.block.MessageBlockMask.MaskType)
                    % We don't need to store any information for Message blocks
                    continue;
                end

                switch maskType
                  case nuttx.internal.block.PublishBlockMask.MaskType
                    sysObjBlock = [block '/SinkBlock'];
                  case nuttx.internal.block.SubscribeBlockMask.MaskType
                    sysObjBlock = [block '/SourceBlock'];

                  otherwise
                    assert(false, sprintf('Unexpected mask type %s for block %s', ...
                                          maskType, block));
                end

                s = nuttx.internal.cgen.NuttxMessageBlockInfo;
                s.TopicType = get_param(block, 'uORBTopic');
                s.SlBusName = get_param(sysObjBlock, 'SLBusName');
                s.Comment = sprintf('For Block %s', block);

                % consistency check
                expectedBusName = ...
                    nuttx.internal.bus.Util.uORBMsgTypeToBusName(s.TopicType, obj.Model);
                assert(strcmpi(s.SlBusName, expectedBusName), ...
                       sprintf('Mismatch: %s, %s', s.SlBusName, expectedBusName));

                switch maskType
                  case nuttx.internal.block.PublishBlockMask.MaskType
                    pubList = [pubList s]; %#ok<AGROW>
                  case nuttx.internal.block.SubscribeBlockMask.MaskType
                    subList = [subList s]; %#ok<AGROW>
                end

            end
        end

    end

end
