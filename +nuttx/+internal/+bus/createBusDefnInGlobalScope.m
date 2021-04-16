function createBusDefnInGlobalScope(uORBMsgType, model)
%This function is for internal use only. It may be removed in the future.

%createBusDefnInGlobalScope - Create Simulink bus object in global scope

%   Copyright 2018-2019 The MathWorks, Inc.

if exist('model', 'var') && ~isempty(model)
    assert(ischar(model));    
end

requiredBus = nuttx.internal.bus.getBusDefnForuORBMsg(uORBMsgType, model);
expectedBusName = nuttx.internal.bus.Util.uORBMsgTypeToBusName(uORBMsgType, model) ;
nuttx.internal.util.CommonUtility.assigninGlobalScope(model, expectedBusName, requiredBus) ;
end

