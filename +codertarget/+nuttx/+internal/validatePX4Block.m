function validatePX4Block(blk)
% VALIDATESERIALBLOCK
% This function validates PX4 blocks against supported .
% Pixhawk hard-wares

% Copyright 2020 The MathWorks, Inc.

if codertarget.pixhawk.internal.isInvalidRegisterUseCase(blk)
    return
end

mdl = codertarget.utils.getModelForBlock(blk);

hardwareBoard = get_param(mdl, 'HardwareBoard');
if strcmp(hardwareBoard, message('px4:hwinfo:PX4HostTarget').getString)
    px4.internal.util.CommonUtility.localizedError('px4:general:SITLNotSupported',get_param(get_param(blk,'ReferenceBlock'),'Name'));
end

end
