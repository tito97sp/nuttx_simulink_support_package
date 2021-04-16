function rootDir = getSpPkgRootDir(varargin)
%GETSPPKGROOTDIR Return the root directory of this support package

%   Copyright 2018-2020 The MathWorks, Inc.

rootDir = fileparts(strtok(mfilename('fullpath'), '+'));
end
