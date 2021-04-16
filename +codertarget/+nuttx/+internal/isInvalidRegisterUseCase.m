function out = isInvalidRegisterUseCase(blk, varargin)
%ISINVALIDREGISTERUSECASE Returns true if register is invalid

% Copyright 2018-2019 The MathWorks, Inc.


mdlName = codertarget.utils.getModelForBlock(blk);

% Prevent block registration under the following invalid use cases:
out = ...
    isequal(get_param(mdlName, 'BlockDiagramType'), 'library') || ... % Adding block to a library
    ~codertarget.target.isCoderTarget(mdlName);                       % Not invoked from Coder Target
end
