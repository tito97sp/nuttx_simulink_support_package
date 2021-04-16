function nuttx_SL_Bus = getBusDefnForuORBMsg(uORBTopicName, model)
% Extract structure data from header file and convert to Simulink bus object

%   Copyright 2018-2020 The MathWorks, Inc.

    nuttxBuildDir = nuttx.internal.util.CommonUtility.getNuttxFirmwareBuildDir ;
    path_to_uorb_msg = fullfile(nuttxBuildDir,'uORB','topics',[uORBTopicName,'.h']);

    %Extract data from generated header file
    topicFileID = fopen(path_to_uorb_msg,'r');

    if topicFileID < 0
        nuttx.internal.util.CommonUtility.localizedError('nuttx:blockmask:InvalidTopicName:NotFoundIn/Build/uORB',uORBTopicName);
    end

    formatSpec = nuttx.internal.util.CommonUtility.getNuttxMsgFormatSpec ;
    % Get text from header file except commented license text
    dataArray = textscan( topicFileID, formatSpec, 'Delimiter','\n', 'CollectOutput',true,'CommentStyle',{'/*','*/'} );
    dataArray = dataArray{1};
    fclose(topicFileID);

    % Start extraction after line struct sensor_accel_s {
    structDefineIndex = find(contains(dataArray,['struct ' uORBTopicName '_s {']), 1);

    varDataTypeColumn ={};
    varNameColumn = {};
    varIndex = structDefineIndex + 2;

    while(true)
        currentStr = strip(char(dataArray{varIndex}));
        if ~isempty(currentStr)
            if strcmp(currentStr, '#ifdef __cplusplus')
                break;
            end
            currentStrSplit = split(currentStr);
            column1 = currentStrSplit{1};

            if strcmp(column1, 'struct')
                % This is a case when one topic is referred within another
                % topic i.e. struct is datatype in generated header file
                structName = currentStrSplit{2};
                uORBName = structName(1:end-2) ;
                nuttx.internal.bus.createBusDefnInGlobalScope(uORBName, model)
                expectedBusName = nuttx.internal.bus.Util.uORBMsgTypeToBusName(uORBName, model) ;
                % Obtain the data-type field column
                varDataTypeColumn = [varDataTypeColumn expectedBusName];
                % Obtain the name field column
                varNameColumn = [varNameColumn strip(currentStrSplit{3},';')];
            else
                % Obtain the data-type field column
                varDataTypeColumn = [varDataTypeColumn currentStrSplit{1}];
                % Obtain the name field column
                varNameColumn = [varNameColumn strip(currentStrSplit{2},';')];
            end
        end
        varIndex = varIndex + 1;

    end

    [varDimensions, varNameColumn] = getDimension(varNameColumn);
    varDataTypeColumn = formatDataType(varDataTypeColumn);
    TotalParseLength = length(varDataTypeColumn);

    % Spawn Bus elements
    clear elems;
    busIndex = 1;

    for index = 1:TotalParseLength
        elems(busIndex) = Simulink.BusElement; %#ok<*AGROW>
        elems(busIndex).Name = strip(char(varNameColumn{index}));
        elems(busIndex).Dimensions = [1 varDimensions{index}];
        elems(busIndex).DimensionsMode = 'Fixed';
        elems(busIndex).DataType = strip(char(varDataTypeColumn{index}));
        elems(busIndex).SampleTime = -1;
        elems(busIndex).Complexity = 'real';
        elems(busIndex).SamplingMode = 'Sample based';
        elems(busIndex).Min = [];
        elems(busIndex).Max = [];
        elems(busIndex).DocUnits = '';
        elems(busIndex).Description = '';
        busIndex = index + 1 ;
    end

    % get header file
    header_file_name = nuttx.internal.cgen.Constants.getGenerateduORBHeader(uORBTopicName);

    % Spawn bus object
    nuttx_SL_Bus = Simulink.Bus;
    nuttx_SL_Bus.HeaderFile = header_file_name;
    nuttx_SL_Bus.Description = nuttx.internal.bus.Util.uORBMsgTypeToBusName(uORBTopicName, '') ;
    nuttx_SL_Bus.DataScope = 'Auto';
    nuttx_SL_Bus.Alignment = -1;
    nuttx_SL_Bus.Elements = elems;

end

function [dimensions, newNameTypeCol] = getDimension( nameTypeColumn )
    [dimensions, newNameTypeCol] = cellfun(@getDimensionOfElement, nameTypeColumn, 'UniformOutput', false);
end

function [size, newNameType] = getDimensionOfElement(nameType)
    nameType = strip(char(nameType)) ;
    bracketStart = strfind(nameType,'[');
    bracketEnd = strfind(nameType,']');
    bracketPos = length(bracketStart);

    if bracketPos == 0
        size = 1;
        formattedNameType = nameType ;
    elseif bracketPos == 1
        size =   str2double( nameType(bracketStart+1 : bracketEnd - 1) );
        formattedNameType = nameType(1:bracketStart-1) ;
    elseif bracketPos>1
        nuttx.internal.util.CommonUtility.localizedError('nuttx:cgen:MultidimensionalElementsNotSupported');
    end

    newNameType = formattedNameType;

end

function varDataType = formatDataType(varDataTypeCoulmn)
    varDataType = cellfun(@formatDataTypeOfElement, varDataTypeCoulmn, 'UniformOutput', false);
end

function dataType = formatDataTypeOfElement(dataTypeElement)
    dataTypeElement = strip(char(dataTypeElement)) ;
    switch(dataTypeElement)
      case('uint64_t')
        dataType = 'uint64';
      case('int64_t')
        dataType = 'int64';
      case('uint32_t')
        dataType = 'uint32';
      case('int32_t')
        dataType = 'int32';
      case('uint16_t')
        dataType = 'uint16';
      case('int16_t')
        dataType = 'int16';
      case('uint8_t')
        dataType = 'uint8';
      case('int8_t')
        dataType = 'int8';
      case('bool')
        dataType = 'boolean';
      case('float')
        dataType = 'single';
      case('char')
        dataType = 'uint8';
      otherwise
        dataType = dataTypeElement;
    end
end
