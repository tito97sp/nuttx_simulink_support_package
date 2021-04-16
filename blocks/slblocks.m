function blkStruct = slblocks
% SLBLOCKS Defines the block library for Nuttx Toolbox

%   Copyright 2018-2019 The MathWorks, Inc.

blkStruct.Name = sprintf('Nuttx Toolbox');
blkStruct.OpenFcn = 'nuttxlib';
blkStruct.MaskDisplay = 'disp(''Nuttx Library'')';
blkStruct.MaskInitialization = '';

% Information for Simulink Library Browser
Browser(1).Library = 'nuttxlib';
Browser(1).Name    = sprintf('Nuttx Toolbox Support Package');
Browser(1).IsFlat  = 0;% Is this library "flat" (i.e. no subsystems)?

blkStruct.Browser = Browser;

% Define information for model updater
blkStruct.ModelUpdaterMethods.fhSeparatedChecks = @ecblksUpdateModel;


