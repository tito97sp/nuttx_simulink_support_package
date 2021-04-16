function cleanupBuildEnvironment()

%

%   Copyright 2018-2020 The MathWorks, Inc.

if isunix && ~ismac
    % Remove added python library from MATLAB path
    currentEnvPath = getenv('LD_LIBRARY_PATH');
    if contains(currentEnvPath, '/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu:')
        newEnvPath = erase(currentEnvPath, '/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu:');
        setenv('LD_LIBRARY_PATH', newEnvPath)
    end
end

buildCmd = getenv('MW_PX4_BUILDCMD');
if ~isempty(buildCmd)
    setenv('MW_PX4_BUILDCMD', '') ;
end

end
