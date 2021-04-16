classdef Util
%This class is for internal use only. It may be removed in the future.

%BUS.UTIL - Utility functions for working with Simulink buses

%   Copyright 2018-2020 The MathWorks, Inc.

    properties(Constant)
        BusNamePrefix = 'nuttx_Bus_'
    end

    %%  General Bus-related utilities
    methods (Static)

        function clearSLBusesInGlobalScope(model)
            nuttx.internal.util.CommonUtility.evalinGlobalScope(model, ['clear ' nuttx.internal.bus.Util.BusNamePrefix]);
        end

        function bus = getBusObjectFromBusName(busName, model)
            bus = nuttx.internal.util.CommonUtility.evalinGlobalScope(model, busName);
        end

        function [bus,busName] = getBusObjectFromMsgType(uORBMsgType, model)
            busName = nuttx.internal.bus.Util.createBusIfNeeded(uORBMsgType, model);
            bus = nuttx.internal.util.CommonUtility.evalinGlobalScope(bdroot(model), busName);
        end

        function busname = getBusNameFromDataTypeStr(dataTypeStr)
            matches = regexp(dataTypeStr, 'Bus:[ ]\s*(.*)', 'tokens');
            if ~isempty(matches)
                busname = matches{1}{1};
            else
                busname = '';
            end
        end

        function [busExists,busName] = checkForBus(uORBMsgType, model)
            busName = nuttx.internal.bus.Util.uORBMsgTypeToBusName(uORBMsgType, model);
            busExists = nuttx.internal.util.CommonUtility.existsInGlobalScope(bdroot(model), busName);
        end

        function busName = createBusIfNeeded(uORBMsgType, model)
            validateattributes(uORBMsgType, {'char'}, {'nonempty'});
            validateattributes(model, {'char'}, {});

            [busExists,busName] = nuttx.internal.bus.Util.checkForBus(uORBMsgType, model);
            if busExists
                return;
            end

            nuttx.internal.bus.createBusDefnInGlobalScope(uORBMsgType, model);
        end

        %%
        function [datatype,busName] = uORBMsgTypeToDataTypeStr(uORBMsgType, model)
        % This is used wherever a Simulink DataTypeStr is required
        % (e.g., for specifying the output datatype of a Constant block)
        % ** DOES NOT CREATE A BUS **
            busName = nuttx.internal.bus.Util.uORBMsgTypeToBusName(uORBMsgType, model);
            datatype = ['Bus: ' busName];
        end

        function busName = uORBMsgTypeToBusName(uORBMsgType, model)
        %
        % uORBMsgTypeToBusName(MSGTYPE,MODEL) returns the bus name
        % corresponding to a uORB message type MSGTYPE .The function
        % uses the following rules:
        %
        % Rule 1 - Generate a name using the format:
        %    nuttx_Bus_<msgtype>
        %
        % Rule 2 - If the result of Rule 1 is longer than 60
        % characters, use the following general format:
        %    nuttx_Bus_<msgtype(1:25)>_<hash>
        % where <hash> is a base 36 hash of the full name (output of
        % rule #1).
        %
        % ** THIS FUNCTION DOES NOT CREATE A BUS OBJECT **

            validateattributes(uORBMsgType, {'char'}, {'nonempty'});
            assert(ischar(model));

            maxlen = 60; choplen=25;
            assert(maxlen <= namelengthmax);

            busName = [nuttx.internal.bus.Util.BusNamePrefix uORBMsgType];

            if length(busName) < maxlen
                busName = matlab.lang.makeValidName(busName, 'ReplacementStyle', 'underscore');
            else
                % add a trailing hash string (5-6 chars) to make the busname unique
                hashStr = nuttx.internal.bus.Util.hashString(busName);

                uORBMsgType = uORBMsgType(1:min(choplen,end));  % get first 25 chars
                busName = matlab.lang.makeValidName(...
                    [nuttx.internal.bus.Util.BusNamePrefix ...
                     uORBMsgType '_' hashStr], ...
                    'ReplacementStyle', 'underscore');
            end
        end

        function isValid = isValidTopicName(uORBMsgType)
            file_path = nuttx.internal.util.CommonUtility.getNuttxConfigDir ;
            msgListTemp = dir([file_path filesep '*.msg']) ;
            msgList = {msgListTemp(:).name} ;
            isValid = any(contains(msgList, [uORBMsgType '.msg'])) ;
        end

        function appendCells = parseFileForUORBInstance(topicFile)
            appendCells = '';
            file = fopen(topicFile);
            buffer = fread(file,'*char')';
            fclose(file);
            if isempty(buffer)
                return;
            end

            lines = strsplit(buffer, '\n');
            findTOPICS = contains(lines, 'TOPICS');
            cells = lines(findTOPICS);

            cellCounter = 1;
            for i=1:length(cells)
                splitLine = strsplit(cells{i}, ' ');
                indexOfTopic = find(strcmp(splitLine, 'TOPICS'));
                for j = (indexOfTopic+1) : length(splitLine)
                    appendCells{cellCounter} =  splitLine{j};
                    cellCounter = cellCounter + 1;
                end
            end
        end

    end

    methods(Static, Access=private)

        function hashStr = hashString(str) 
            persistent hashStringMap;
            rng('shuffle');
            % Hash characters can be alphanumeric ([0-9|a-z|A-Z]) or underscores (_)
            randomCharArray = ['_' 'a':'z' '0':'9' 'A':'Z' ];
            
            if isempty(hashStringMap)
                hashStringMap = containers.Map;
            end
            
            % If there is no random keyword generated for the topic name
            % yet, generate one and store it for retrieval.
            if ~isKey(hashStringMap, str)
                idx = randi(numel(randomCharArray), 1, 6); % returns a random array of 1x6
                hashStringMap(str) = randomCharArray(idx);
            end
            hashStr = hashStringMap(str) ;
        end

        function localizedError(id, varargin)
            e = MSLException([],id, getString(message(id, varargin{:})));
            e.throwAsCaller;
        end
    end

end
