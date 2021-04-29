classdef Constants < handle
%This class is for internal use only. It may be removed in the future.

%cgen.Constants - Constants used for generating and including headers
%in uORB code

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

    properties(Constant)

        uORBReadCode = struct(...
            'HeaderFile', 'MW_uORB_Read.h', ...
            'SourceFile', 'MW_uORB_Read.cpp' ...
        )

        uORBWriteCode = struct(...
            'HeaderFile', 'MW_uORB_Write.h', ...
            'SourceFile', 'MW_uORB_Write.cpp' ...
        )

        InitCode = struct(...
            'HeaderFile', 'MW_uORB_Init.h' ...
        )

        GeneratedCode = struct(...
            'HeaderFile', 'MW_uORB_busstruct_conversion.h' ...
        )

        % PWMOutputs = struct(...
        %     'HeaderFile', 'MW_PX4_PWM.h', ...
        %     'SourceFile', 'MW_PX4_PWM.cpp' ...
        % )
    end

    properties
        generateduORBHeader
    end

    methods
        function obj = Constants
        % Enable code to be generated even this file is p-coded
            coder.allowpcode('plain');
        end
    end

    methods(Static)
        function header = getGenerateduORBHeader(uORBTopic)
            header = ['<uORB/topics/' uORBTopic '.h>'];
        end

        function includeGenerateduORBHeader(uORBTopic)
            coder.cinclude(getGenerateduORBHeader(uORBTopic));
        end

        function includeCommonHeaders()
            coder.cinclude('<uORB/uORB.h>');
            coder.cinclude('<poll.h>');
        end
    end

end
