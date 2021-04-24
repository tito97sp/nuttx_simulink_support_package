classdef Util
%This class is for internal use only. It may be removed in the future.

%CGEN.UTIL - Utility functions for generating codes for uORB Blocks

%   Copyright 2018-2020 The MathWorks, Inc.

    properties(Constant)
        BusNamePrefix = 'nuttx_Bus_'
    end

    %%  General Bus-related utilities
    methods (Static)

        function msgTypes = getBlockLevelMessageTypesInModel(model)
        %getBlockLevelMessageTypesInModel Get all message types used in model
            validateattributes(model, {'char'}, {'nonempty'});
            blockMsgTypes = nuttx.internal.cgen.Util.getNuttxuORBBlocksInModel(model);
            msgTypes = unique( blockMsgTypes );
        end

        function [topLevelMsgTypes, ...
                  pubSubMsgBlockList] = getNuttxuORBBlocksInModel(model)

            validateattributes(model, {'char'}, {'nonempty'});

            topLevelMsgTypes = {};
            pubSubMsgBlockList = {};
            modelRefNames = find_mdlrefs(model);

            for i=1:numel(modelRefNames)
                % Find Publish, Subscribe, and uORB Message Blocks
                currentModel = modelRefNames{i};
                load_system(currentModel);
                blockList = ...
                    nuttx.internal.cgen.Util.listBlocks(currentModel, ...
                                                      ['(' ...
                                    nuttx.internal.block.PublishBlockMask.MaskType, '|', ...
                                    nuttx.internal.block.SubscribeBlockMask.MaskType, '|', ...
                                    nuttx.internal.block.MessageBlockMask.MaskType ...
                                    ')']);

                if ~isempty(blockList)
                    topLevelMsgTypes = [topLevelMsgTypes; get_param(blockList,'uORBTopic')]; %#ok<AGROW>
                    pubSubMsgBlockList = [pubSubMsgBlockList; blockList]; %#ok<AGROW>
                end
            end

            % The following topics have a parent topic. Hardcoding the
            % values as there is no efficient way to parse the topics and
            % figure out if they have parent
            if nnz(contains(topLevelMsgTypes, 'position_setpoint_triplet')) > 0
                topLevelMsgTypes = [topLevelMsgTypes; 'position_setpoint'];
            elseif contains(topLevelMsgTypes, 'esc_report')
                topLevelMsgTypes = [topLevelMsgTypes; 'esc_status'];
            end

        end

        function blockList = listBlocks(model, maskType)
        %listBlocks List blocks of a specific mask type in a model
        %   Note that MASKTYPE can contain regular expressions, e.g.
        %   BLOCKLIST is returned as a column vector

        % To change it to libinfo once added to Library
            lbdata = libinfo(bdroot(model), ...
                             'LookUnderMasks', 'all', ...
                             'Regexp', 'on', ...
                             'MaskType', maskType);
            blockList = {lbdata(:).Block};
            blockList = blockList(:);
        end

        function isTopLevel = isTopLevelModel(buildInfo)
        %isTopLevelModel Determine if a given model is a top-level or referenced model
        %   ISTOPLEVELMODEL(BUILDINFO) returns TRUE if the model
        %   represented by BUILDINFO is a top-level model.
        %
        %   ISTOPLEVELMODEL(BUILDINFO) returns FALSE if the model is
        %   used as a referenced model

            validateattributes(buildInfo, {'RTW.BuildInfo'}, {'scalar'}, 'isTopLevelModel', 'buildInfo');

            [~, buildArgValue] = findBuildArg(buildInfo, 'MODELREF_TARGET_TYPE');
            isTopLevel = strcmp(buildArgValue, 'NONE');
        end

        function modelRefNames = uniqueModelRefNames(buildInfo)
        %uniqueModelRefNames Get names of all model references in model
        %   MODELREFNAMES = uniqueModelRefNames(BUILDINFO) returns the
        %   names of all model references listed in the BUILDINFO for
        %   the current model. The list of MODELREFNAMES will only
        %   contain unique entries.

            validateattributes(buildInfo, {'RTW.BuildInfo'}, {'scalar'}, 'uniqueModelRefNames', 'buildInfo');

            modelRefNames = {};
            if ~isempty(buildInfo.ModelRefs)
                modelRefPaths = arrayfun(@(ref) ref.Path, buildInfo.ModelRefs, 'UniformOutput', false);

                modelRefNames = cell(1,numel(modelRefPaths));
                for i = 1:numel(modelRefPaths)
                    [~, modelRefNames{i}, ~] = fileparts(modelRefPaths{i});
                end

                % Only find the unique model reference names
                modelRefNames = unique(modelRefNames, 'stable');
            end
        end


    end
end
