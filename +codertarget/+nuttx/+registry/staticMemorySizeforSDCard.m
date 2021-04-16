function ramSize = staticMemorySizeforSDCard(modelName,varargin)
% STATICMEMORYSIZEFORSDCARD Callback for SD Card Logging memory requirements

% Copyright 2020 The MathWorks, Inc.

% Using persistent variable as this function is called in multiple places.
% Having a persistent variable will prevent execution of this function
% every time and in turn save a few seconds

try
    
    modelHandle = get_param(modelName,'Handle');
    cs = getActiveConfigSet(modelName);
    modelFunctionHandle = str2func(modelName);
    
    % Compile the model to get all the compiled parameters
    modelFunctionHandle([],[],[],'compile');
    
    %The below lines finds the handles of all the Scopes, To Workspace and
    %Outports in the model. The 'IncludeCommented' NV pair is et to false
    %to exclude commented blocks.
    scopeHandle = Simulink.findBlocksOfType(modelHandle,'Scope', Simulink.FindOptions('IncludeCommented', false));
    toWorkspaceHandle = Simulink.findBlocksOfType(modelHandle,'ToWorkspace', Simulink.FindOptions('IncludeCommented', false));
    outportHandle = Simulink.findBlocksOfType(modelHandle,'Outport', Simulink.FindOptions('SearchDepth', 1, 'IncludeCommented', false));
    
    % Model start time, stop time and model step size
    startTime = str2double(get_param(modelName,'StartTime'));
    finalTime = getModelFinalTime(modelName);
    modelSampleTime = str2double(get_param(modelHandle, 'CompiledStepSize'));
    
    %handleArr is structure with below fields, to hold information about
    %all the blocks used for logging signals
    % Type - To Workspace/Scope/Outport/Time
    % Handle - Handle of the block
    % SampleTime - Sample Time of the signal at which it is logged
    % Decimation
    % localDataPoints - updated local data points to last
    
    handleArr = [];
    if strcmp(cs.getProp('SaveTime'), 'on')
        %If the SaveTime is 'on' from config set
        
        handleArr(1).Type = 'SaveTime';
        handleArr(1).Handle = nan;
        handleArr(1).SampleTime = modelSampleTime;
        handleArr(1).Decimation = str2double(cs.getProp('Decimation'));
        localDataPointsTime = calculatelocalDataPoints(handleArr(1).SampleTime,handleArr(1).Decimation,finalTime);
        handleArr(1).localDataPoints = localDataPointsTime;
        
    end
    
    %Update all scopes
    for nBlock = 1 : length(scopeHandle)
        handleArr = updateHandleArr(handleArr,scopeHandle(nBlock),modelName);
    end
    
    %Update all To Workspace
    for nBlock = 1 : length(toWorkspaceHandle)
        handleArr = updateHandleArr(handleArr,toWorkspaceHandle(nBlock),modelName);
    end
    
    %Update all Outports
    for nBlock = 1 : length(outportHandle)
        handleArr = updateHandleArr(handleArr,outportHandle(nBlock),modelName);
    end
    
    % Terminate the model compilation
    modelFunctionHandle([],[],[],'term');
    
    %Verify if the settings for the blocks are already optimal. If not
    %throw a question dialog pop up for the user.
    
    isOptimal = checkOptimalSettings(handleArr,modelName);
    if(~isOptimal)
        answer = questdlg(message('px4:general:SDCardQuestionDLG').getString, ...
            message('px4:general:UpdateModel').getString, ...
            message('px4:general:SDFixIt').getString,...
            message('px4:general:SDCancel').getString,...
            message('px4:general:SDFixIt').getString);
        % Handle response
        switch answer
            %Update the model only if the user clicks 'Fix It'
            case message('px4:general:SDFixIt').getString
                setLimitDataPoints(handleArr,modelHandle);
        end
    end
    
    % Compile the model to get all the compiled parameters
    modelFunctionHandle([],[],[],'compile');
    
    ramSize = 0;
    
    % If time is selected to be logged in configuration parameters, log it in
    % double format
    if strcmp(cs.getProp('SaveTime'), 'on')
        maxRows = 0;
        % Decimation data from configset for time
        if strcmp(cs.getProp('LimitDataPoints'), 'on')
            % If the number of points to be logged is selected in configset then read the value
            maxRows = str2double(cs.getProp('MaxDataPoints'));
            if maxRows == Inf
                maxRows = 0;
            end
            decimation = str2double(cs.getProp('Decimation'));
        else
            decimation = 1;
        end
        % Port width, frame data, port dimensions and port datatype for time is
        % 1
        nCols = 1;
        frameData = 0;
        dimensionData = [1 1];
        nDims = dimensionData(1);
        dimensions = dimensionData(2:end);
        if frameData > 0
            frameSize = dimensions(1);
        else
            frameSize = 1;
        end
        portDataType = 'double';
        elementSize = getSizeofDataType(portDataType);
        % Logging format for the time
        dataFormat = 'Array';
        % Memory calculation
        titleLength = 0;
        blockNameLength = 0;
        blockType = 'Time';
        ramSize = ramSize + memorySizeCalculator(startTime, finalTime, modelSampleTime, modelSampleTime, maxRows,...
            decimation, nCols, frameData, nDims, dimensions, frameSize, elementSize, 0, dataFormat,blockNameLength,titleLength, blockType);
    end
    % sizeof(LogInfo)32
    ramSize = ramSize + 32;
    % Add additional buffer memory of 128
    ramSize = ramSize + 128;
    %     disp(['ramSize = ',num2str(ramSize)])
    % Calculate memory requirement for Scope blocks
    for nBlock = 1 : length(scopeHandle)
        blockSampleTime = get_param(scopeHandle(nBlock), 'CompiledSampleTime');
        % If the number of points to be logged is selected then read the value
        if strcmp(get_param(scopeHandle(nBlock), 'DataLoggingLimitDataPoints'), 'on')
            maxRows = str2double(get_param(scopeHandle(nBlock), 'DataLoggingMaxPoints'));
            if maxRows == Inf
                maxRows = 0;
            end
        else
            maxRows = 0;
        end
        % Decimation data
        if strcmp(get_param(scopeHandle(nBlock), 'DataLoggingDecimateData'), 'on')
            decimation = str2double(get_param(scopeHandle(nBlock), 'DataLoggingDecimation'));
        else
            decimation = 1;
        end
        % Port width, frame data, port dimensions and port datatype
        portWidths = get_param(scopeHandle(nBlock), 'CompiledPortWidths');
        nCols = portWidths.Inport;
        portFrameData = get_param(scopeHandle(nBlock), 'CompiledPortFrameData');
        frameData = portFrameData.Inport;
        portDimensions = get_param(scopeHandle(nBlock), 'CompiledPortDimensions');
        dimensionData = portDimensions.Inport;
        nDims = dimensionData(1);
        dimensions = dimensionData(2:end);
        if frameData > 0
            frameSize = dimensions(1);
        else
            frameSize = 1;
        end
        dataKind = get_param(scopeHandle(nBlock), 'CompiledPortComplexSignals');
        isComplex = dataKind.Inport;
        portDataType = get_param(scopeHandle(nBlock), 'CompiledPortDataTypes');
        elementSize = getSizeofDataType(portDataType.Inport{1});
        % Logging format for the signal
        dataFormat = get_param(scopeHandle(nBlock), 'DataLoggingSaveFormat');
        % Get length of full Block Name
        blockNameLength = length(getfullname(scopeHandle(nBlock)));
        % Get length of Block Title
        titleLength = length(get_param(scopeHandle(nBlock),'Title'));
        %Get block type
        blockType = get_param(scopeHandle(nBlock),'BlockType');
        % Memory calculation
        ramSize = ramSize + memorySizeCalculator(startTime, finalTime, modelSampleTime, blockSampleTime, maxRows, decimation, nCols,...
            frameData, nDims, dimensions, frameSize, elementSize, isComplex, dataFormat, blockNameLength, titleLength,blockType);
        %         disp(['ramSize = ',num2str(ramSize)])
    end
    
    % Calculate memory requirement for ToWorkspace blocks
    for nBlock = 1 : length(toWorkspaceHandle)
        blockSampleTime = get_param(toWorkspaceHandle(nBlock), 'CompiledSampleTime');
        % If the number of points to be logged is selected then read the value
        maxRows = str2double(get_param(toWorkspaceHandle(nBlock), 'MaxDataPoints'));
        if maxRows == Inf
            maxRows = 0;
        end
        % Decimation data
        decimation = str2double(get_param(toWorkspaceHandle(nBlock), 'Decimation'));
        % Port width, frame data, port dimensions and port datatype
        portWidths = get_param(toWorkspaceHandle(nBlock), 'CompiledPortWidths');
        nCols = portWidths.Inport;
        portFrameData = get_param(toWorkspaceHandle(nBlock), 'CompiledPortFrameData');
        frameData = portFrameData.Inport;
        portDimensions = get_param(toWorkspaceHandle(nBlock), 'CompiledPortDimensions');
        dimensionData = portDimensions.Inport;
        nDims = dimensionData(1);
        dimensions = dimensionData(2:end);
        if frameData > 0
            frameSize = dimensions(1);
        else
            frameSize = 1;
        end
        dataKind = get_param(toWorkspaceHandle(nBlock), 'CompiledPortComplexSignals');
        isComplex = dataKind.Inport;
        portDataType = get_param(toWorkspaceHandle(nBlock), 'CompiledPortDataTypes');
        elementSize = getSizeofDataType(portDataType.Inport{1});
        % Logging format for the signal
        dataFormat = get_param(toWorkspaceHandle(nBlock), 'SaveFormat');
        % Get length of full Block Name
        blockNameLength = length(getfullname(toWorkspaceHandle(nBlock)));
        % Get length of Block Title
        titleLength = 0;
        %Get block type
        blockType = get_param(toWorkspaceHandle(nBlock),'BlockType');
        % Memory calculation
        ramSize = ramSize + memorySizeCalculator(startTime, finalTime, modelSampleTime, blockSampleTime,...
            maxRows, decimation, nCols, frameData, nDims, dimensions, frameSize, elementSize, isComplex, dataFormat, blockNameLength,titleLength,blockType);
        %         disp(['ramSize = ',num2str(ramSize)])
    end
    
    % Calculate memory requirement for Outport
    if strcmp(cs.getProp('SaveOutput'), 'on')
        for nBlock = 1 : length(outportHandle)
            %For outport and time, modelsample time is taken
            blockSampleTime = modelSampleTime;
            %             blockSampleTime = get_param(outportHandle(nBlock), 'CompiledSampleTime');
            maxRows = 0;
            % Decimation data from configset
            if strcmp(cs.getProp('LimitDataPoints'), 'on')
                % If the number of points to be logged is selected in configset then read the value
                maxRows = str2double(cs.getProp('MaxDataPoints'));
                if maxRows == Inf
                    maxRows = 0;
                end
                decimation = str2double(cs.getProp('Decimation'));
            else
                decimation = 1;
            end
            % Port width, frame data, port dimensions and port datatype
            portWidths = get_param(outportHandle(nBlock), 'CompiledPortWidths');
            nCols = portWidths.Inport;
            portFrameData = get_param(outportHandle(nBlock), 'CompiledPortFrameData');
            frameData = portFrameData.Inport;
            portDimensions = get_param(outportHandle(nBlock), 'CompiledPortDimensions');
            dimensionData = portDimensions.Inport;
            nDims = dimensionData(1);
            dimensions = dimensionData(2:end);
            if frameData > 0
                frameSize = dimensions(1);
            else
                frameSize = 1;
            end
            dataKind = get_param(outportHandle(nBlock), 'CompiledPortComplexSignals');
            isComplex = dataKind.Inport;
            portDataType = get_param(outportHandle(nBlock), 'CompiledPortDataTypes');
            elementSize = getSizeofDataType(portDataType.Inport{1});
            % Logging format for the signal
            dataFormat = cs.getProp('SaveFormat');
            % Get length of full Block Name
            blockNameLength = length(getfullname(outportHandle(nBlock)));
            % Get length of Block Title
            titleLength = 0;
            %Get block type
            blockType = get_param(outportHandle(nBlock),'BlockType');
            % Memory calculation
            ramSize = ramSize + memorySizeCalculator(startTime, finalTime, modelSampleTime, blockSampleTime,...
                maxRows, decimation, nCols, frameData, nDims, dimensions, frameSize, elementSize, isComplex, dataFormat,blockNameLength,titleLength,blockType );
            %             disp(['ramSize = ',num2str(ramSize)])
        end
    end
    
    
    %Throw warning to avoid Linker issues with large array size
    targetHardware = get_param(cs,'HardwareBoard');
    boardRam = px4.internal.util.CommonUtility.getBoardRAM(targetHardware);
    thresholdRam = (boardRam/2)-10;
    if(ramSize > (thresholdRam*1024))
        warning(message('px4:general:SDCardMemoryLinkerError').getString);
    end
    
    %Throw error to avoid compilation issues with large array size
    if(ramSize > ((2^31)-1))
        error(message('px4:general:SDCardMemoryCompileError').getString);
    end
    
    % Terminate the model compilation
    modelFunctionHandle([],[],[],'term');
    
    
catch ME
    % Terminate the model compilation
    modelFunctionHandle([],[],[],'term');
    
    throw(ME);
end
end

function memorySize = memorySizeCalculator(startTime, finalTime, modelSampleTime, blockSampleTime,...
    maxRows, decimation, nCols, frameData, ~, dimensions, frameSize, elementSize, isComplex, dataFormat, blockNameLength,titleLength,blockType)
% MEMORYSIZECALCULATOR Function to calculate memory size similar to
% ert_targets_logging.c file

% Default buffer size for signal defined in ert_target_logging.c file
defaultBufferSize = 1024;

% Set the stop time to 10 to limit the memory to be used if it is set to
% Inf
if finalTime == Inf
    finalTime = 10;
end

if finalTime > startTime && finalTime ~= Inf
    if blockSampleTime(1) == -2
        stepSize = finalTime;
        %In ert_targets_logging.c, block sample time of Inf is treated as
        %model base rate
    elseif blockSampleTime(1) == -1 || blockSampleTime(1) == 0 || blockSampleTime(1) == inf
        stepSize = modelSampleTime;
    else
        stepSize = blockSampleTime(1);
    end
    if stepSize == 0
        nRows = maxRows + 1;
    else
        nPoints = 1 + floor((finalTime - startTime) / stepSize);
        if ( stepSize *(nPoints - 1) < (finalTime - startTime) )
            nPoints = nPoints + 1;
        end
        if frameData > 0
            nPoints = nPoints * frameSize;
        end
        nPoints = nPoints / decimation;
        if nPoints ~= floor(nPoints)
            nPoints = nPoints + 1;
        end
        if nPoints > 65535
            nRows  = 65535;
        else
            nRows = nPoints;
        end
        if ((maxRows > 0) && (maxRows < nRows))
            nRows = maxRows;
        end
    end
elseif startTime == finalTime
    if frameData > 0
        nRows = frameSize;
    else
        nRows = 1;
    end
    if ((maxRows > 0) && (maxRows < nRows))
        nRows = maxRows;
    end
elseif maxRows > 0
    nRows = maxRows;
else
    if modelSampleTime == 0
        nRows = maxRows + 1;
    else
        nRows = defaultBufferSize;
    end
end

if frameData > 0
    nColumns = dimensions(2);
else
    nColumns = nCols;
end

% Time will be logged with data for Structure with time and Array format
timeSize = nRows * getSizeofDataType('double');
if strcmp(blockType,'Time')
    dataSize = 0;
else
    dataSize = nRows * nColumns * elementSize;
end
if strcmp(dataFormat, 'Structure With Time') || strcmp(dataFormat, 'StructureWithTime')
    
    % With each size byte aligned
    % Total size 2168 = sizeof(StructLogVar) 136 + (2* sizeof(LogVar) 224) +
    % dimensions 184 + label 176 + plotstyles (256 for scope, 336 for workspace) + titles (176 + dynamic) +
    % statenames 176 + blocknames 176 + crossmodelref 184 + blockname (176 + 2*blockNameLength).
    % Not considering additional sizes for variable dimensions as it is not
    % supported for embedded targets
    sizes = [136,224,224,184,176,336,176+2*titleLength,176,176,184,176+2*blockNameLength];
    structureSize = memAlign(sizes);
    
elseif strcmp(dataFormat, 'Structure')
    
    % Total size 1091 = sizeof(StructLogVar) 136 + Empty matrix data 176 +
    % sizeof(LogVar) 224 + dimensions 184 + label 176 + plotstyles (256 for scope, 336 for workspace) + titles (176 + dynamic) +
    % blocknames 176 + statenames 176 +
    % crossmodelref 184 + blockname (176 + dynamic).
    % Not considering additional sizes for variable dimensions as it is not
    % supported for embedded targets
    sizes = [136,176,224,184,176,336,176,176,176,184,176+2*blockNameLength];
    structureSize = memAlign(sizes);
    
    %Time is not logged for type structure
    timeSize = 0;
else
    %-------------TI Stuff----------------------
    %     % sizeof(LogVar) 120
    %     structureSize = timeSize + 120;
    %-------------TI Stuff----------------------
    
    % sizeof(LogVar) 224
    structureSize = 224;
end
if isComplex
    dataSize = dataSize * 2;
end
memorySize = dataSize + timeSize + structureSize;
% disp(['blockType = ',blockType,' dataFormat =',dataFormat,' blockSampleTime =',num2str(blockSampleTime)])
% disp(['dataSize = ',num2str(dataSize)])
% disp(['timeSize = ',num2str(timeSize)])
% disp('---------------------')

end

function totalSize = memAlign(sizes)
% Calculate the memory alignment for 8-bits
alignValue = mod(sizes, 8);
if nnz(alignValue)
    nnzIndices = find(alignValue);
    for k=1:length(nnzIndices)
        sizes(nnzIndices(k)) = sizes(nnzIndices(k)) + (8 - alignValue(nnzIndices(k)));
    end
end
totalSize = sum(sizes);
end

function  elementSize = getSizeofDataType(portDataType)
% GETSIZEOFDATA - Function that returns the size of the data type as per
% the TI processors
switch portDataType
    case 'uint8'
        elementSize = 1;
    case 'int8'
        elementSize = 1;
    case 'boolean'
        elementSize = 1;
    case 'uint16'
        elementSize = 2;
    case 'int16'
        elementSize = 2;
    case 'short'
        elementSize = 2;
    case 'uint32'
        elementSize = 4;
    case 'int32'
        elementSize = 4;
    case 'uint64'
        elementSize = 8;
    case 'int64'
        elementSize = 8;
    case 'double'
        elementSize = 8;
    case 'single'
        elementSize = 4;
    otherwise
        elementSize = 4;
end
end

function setLimitDataPoints(handleArr,modelHandle)
%Update the 'Limit data points to last' of all the blocks if the user selects
%'Fix It' option.
% The optimal 'Limit data points to last' is calculated and stored in the
% handleArr structure for each block. That value is applied using set_param
% if the user selects 'Fix It'
if(~isempty(handleArr))
    % Loop through the blocks and update as per the block type
    for idx = 1:length(handleArr)
        switch handleArr(idx).Type
            case 'Scope'
                set_param(handleArr(idx).Handle,'DataLoggingMaxPoints',num2str(handleArr(idx).localDataPoints));
            case 'ToWorkspace'
                set_param(handleArr(idx).Handle,'MaxDataPoints',num2str(handleArr(idx).localDataPoints));
            case 'Outport'
                set_param(modelHandle,'MaxDataPoints',num2str(handleArr(idx).localDataPoints));
            case 'SaveTime'
                set_param(modelHandle,'MaxDataPoints',num2str(handleArr(idx).localDataPoints));
            otherwise
                disp(message('px4:general:UnknownBlock').getString);
                
        end
    end
end
end

function localDataPoints = calculatelocalDataPoints(SampleTime,Decimation,finalTime)
%This function calculates the optimal local data points for each block
%based on the final time, sample time, and the time criterion selected for
%each MAT File. For Pixhawk, we have selected 3.5s per MAT File to give
%sufficient time to close and open new files.

minTimePerMATFile = 3.5;
totalDataPoints = (finalTime/SampleTime)/Decimation;
numMATFile = floor(finalTime/minTimePerMATFile);
localDataPoints = ceil(totalDataPoints/numMATFile)*2;

end

function isOptimal = checkOptimalSettings(handleArr,modelName)
%This function checks if all the blocks have the optimized local data
%points to last setting.
isOptimal = true;
modelHandle = get_param(modelName,'Handle');
if(~isempty(handleArr))
    for idx = 1:length(handleArr)
        switch handleArr(idx).Type
            case 'Scope'
                isOptimal = handleArr(idx).localDataPoints == str2double(get_param(handleArr(idx).Handle,'DataLoggingMaxPoints'));
            case 'ToWorkspace'
                isOptimal = handleArr(idx).localDataPoints == str2double(get_param(handleArr(idx).Handle,'MaxDataPoints'));
            case 'Outport'
                isOptimal = handleArr(idx).localDataPoints == str2double(get_param(modelHandle,'MaxDataPoints'));
            case 'SaveTime'
                isOptimal = handleArr(idx).localDataPoints == str2double(get_param(modelHandle,'MaxDataPoints'));
            otherwise
                disp(message('px4:general:UnknownBlock').getString);
        end
        %If any of the blocks is not set to its optimal
        %number, false is returned, otherwise true.
        if(~isOptimal)
            return;
        end
    end
end

end

function finalTime = getModelFinalTime(modelName)
finalTime = str2double(get_param(modelName,'StopTime'));
% Set the stop time to 10 to limit the memory to be used if it is set to
% Inf
if finalTime == Inf
    finalTime = 10;
end
end


function handleArr = updateHandleArr(handleArr,blockHandle,modelName)
%Update the HandleArr for every block selected for logging
if(isempty(handleArr))
    idx = 1;
else
    idx = length(handleArr)+1;
end
handleArr(idx).Type = get_param(blockHandle,'BlockType');
handleArr(idx).Handle = blockHandle;
switch handleArr(idx).Type
    case 'Scope'
        SampleTime = get_param(blockHandle, 'CompiledSampleTime');
        handleArr(idx).SampleTime = SampleTime(1);
        if strcmp(get_param(blockHandle, 'DataLoggingDecimateData'), 'on')
            decimation = str2double(get_param(blockHandle, 'DataLoggingDecimation'));
        else
            decimation = 1;
        end
        handleArr(idx).Decimation = decimation;
    case 'ToWorkspace'
        SampleTime = get_param(blockHandle, 'CompiledSampleTime');
        handleArr(idx).SampleTime = SampleTime(1);
        handleArr(idx).Decimation = str2double(get_param(blockHandle, 'Decimation'));
    case 'Outport'
        modelHandle = get_param(modelName,'Handle');
        modelSampleTime = str2double(get_param(modelHandle, 'CompiledStepSize'));
        handleArr(idx).SampleTime = modelSampleTime;
        handleArr(idx).Decimation = str2double(get_param(modelHandle, 'Decimation'));
    otherwise
        disp(message('px4:general:UnknownBlock').getString);
end
finalTime = getModelFinalTime(modelName);
%Calculate the optimal 'Limit Data Points to last' for all blocks and
%update the 'localDataPoints' field of the handleArr structure
localDataPoints = calculatelocalDataPoints(handleArr(idx).SampleTime,handleArr(idx).Decimation,finalTime);
handleArr(idx).localDataPoints = localDataPoints;
end
