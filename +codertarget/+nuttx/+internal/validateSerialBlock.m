function validateSerialBlock(blk)
% VALIDATESERIALBLOCK
% This function validates Serial Read and Serial Write blocks.
%
% If the Port name for any two blocks is same then validate if
% Baud rate, Parity, Stop Bits are same.

% Copyright 2018-2020 The MathWorks, Inc.

if codertarget.pixhawk.internal.isInvalidRegisterUseCase(blk)
    return
end

BlockType = get_param(blk,'System');
BlockType = strsplit(BlockType,'.');
BlockType = BlockType{end};

switch BlockType
    case 'PX4SCIRead'
        FamilyName = 'SerialReceive';
    case 'PX4SCIWrite'
        FamilyName = 'SerialTransmit';
end
block = strsplit(FamilyName,'Serial');
block = ['Serial ',char(block(2))];

%Uncomment below to restrict multiple serial rx/tx blocks with same port
%---------------------------Working----------------------------------------
% opts.familyName = FamilyName;
% opts.parameterName = [FamilyName,'_Port'];
% opts.parameterValue = get_param(blk, 'SCIModule');
% opts.parameterCallback = {'allDifferent'};
%
% errorID = 'px4:general:SerialBlockConflict';
% opts.errorID = {errorID};
% opts.errorArgs = {get_param(blk, 'SCIModule'),block};
% lf_registerBlockCallbackInfo(opts);
%---------------------------Working----------------------------------------

%Check for Conflict between Ext Mode COM Port and Serial block COM Port
portName = get_param(blk, 'SCIModule');

mdl = codertarget.utils.getModelForBlock(blk);
hCS = getActiveConfigSet(mdl);
data = codertarget.data.getData(hCS);

%Conflict check with External Mode
if isfield(data, 'ExtMode') && isfield(data.ExtMode, 'Running') && isequal(data.ExtMode.Running, 'on')
    if isfield(data, 'ExtSerialPort') && strcmpi(data.ExtSerialPort,portName)
        error(message('px4:general:SerialConflictExt',portName,block).getString);
    end
end

%Conflict check with PIL
modelCodegenMgr = coder.internal.ModelCodegenMgr.getInstance(getModel(hCS));
if ~isempty(modelCodegenMgr) && isfield(modelCodegenMgr.MdlRefBuildArgs, 'XilInfo')
    xilInfo = modelCodegenMgr.MdlRefBuildArgs.XilInfo;
    if xilInfo.IsPil
        %get PIL target serial port
        if isfield(data, 'PILHardwareSerialPort_Checkbox') &&(data.PILHardwareSerialPort_Checkbox == 0)
            hardwareSerialPort = data.PILSerialPort;
        else
            hardwareSerialPort = data.ExtSerialPort;
        end
        if strcmpi(hardwareSerialPort,portName)
            error(message('px4:general:SerialConflictPIL',portName,block).getString);
        end
    end
end

%Conflict check with MAVLink
if(isfield(data,'enableMavlinkCheckbox') && data.enableMavlinkCheckbox)
    if (contains(portName,'ACM0')) %If the serial block is using the ACM0 serial port and MAVLink is enabled, error out
        error(message('px4:general:SerialBlockMavlinkConflict',portName,block).getString);
    end
end

%Conflict check with Connected I/O (exclude for model update)
if matlabshared.svd.internal.isSimulinkIoEnabled && ~strcmp(get_param(mdl, 'SimulationStatus'), 'updating')
    if (isequal(portName,'/dev/ttyACM0')) %If the serial block is using the /dev/ttyACM0 serial port, error out
       error(message('px4:general:SerialConflictIO',portName,block).getString);
    end
end
% validates block against supported Pixhawk hardwares
codertarget.pixhawk.internal.validatePX4Block(blk);

end
