classdef Timer < rtw.connectivity.Timer
    % TIMER Get timing information for PIL application
    %
    %   See also RTW.CONNECTIVITY.TIMER
    
    %   Copyright 2019 The MathWorks, Inc.
    
    methods
        function this = Timer(varargin)
            % Look for an input providing ticks per second
            if (nargin > 0)
                ticksPerSecond = varargin{1};
            else
                ticksPerSecond = 1e6;
            end
            % Configure data type returned by timer reads
            this.setTimerDataType('uint32');
            
            % The micros() function returns multiple of 10µ
            this.setTicksPerSecond(ticksPerSecond);
            
            % The timer counts upwards
            this.setCountDirection('up');
            
            % Get installation path
            rootDir = codertarget.pixhawk.internal.getSpPkgRootDir;
            
            % Configure source files required to access the timer
            headerFile = fullfile(rootDir,...
                'include',...
                'profiler_timer.h');
            
            sourceFile = fullfile(rootDir,...
                'src',...
                'profiler_timer.c');
            
            this.setSourceFile(sourceFile);
            this.setHeaderFile(headerFile);
            
            % Configure the expression used to read the timer
            readTimerExpression = 'profileTimerRead()';
            this.setReadTimerExpression(readTimerExpression);
        end
    end
end

