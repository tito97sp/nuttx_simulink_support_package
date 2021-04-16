function rootDir = getSetupScriptsDir()
%GETSETUPSCRIPTSDIR Return the path of the folder where shell scripts are
%placed

%   Copyright 2018-2019 The MathWorks, Inc.

rootDir = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,'lib','scripts');
end
