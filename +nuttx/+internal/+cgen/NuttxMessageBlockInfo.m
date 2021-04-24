classdef NuttxMessageBlockInfo < nuttx.internal.cgen.NuttxBlockInfo
%This class is for internal use only. It may be removed in the future.

%NuttxMessageBlockInfo is a utility class that encapsulates information about
%   a single Nuttx block that handles Nuttx messages in a Simulink model.
%
%   See also: cgen.NuttxModelInfo

%   Copyright 2018-2020 The MathWorks, Inc.

    properties
        TopicType
        SlBusName
    end

end
