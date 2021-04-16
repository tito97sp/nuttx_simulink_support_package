function [mapName, relativePathToMapFile, found] = getBlockHelpMapNameAndPath(block_type)
%  Returns the mapName and the relative path to the maps file for this block_type

% Internal note: 
%   First column is the "System object name", corresponding to the block, 
%   Second column is the anchor ID, the doc uses for the block.
%   For core blocks, the first column is the 'BlockType'.

% Copyright 2018-2020 The MathWorks, Inc.
    
    blks = {...
    'px4.internal.block.PWM'    'px4libpwm'              ;...
    'px4.internal.block.PX4SCIRead'    'px4libserialreceive'              ;...
    'px4.internal.block.PX4SCIWrite'    'px4libserialtransmit'              ;...
    'px4.internal.block.ParameterUpdate'    'px4libreadparameter'              ;...
    'px4.internal.block.PX4I2CRead'    'px4libi2cread'              ;...
    'px4.internal.block.PX4I2CWrite'    'px4libi2cwrite'              ;...    
    };

relativePathToMapFile = '';
found = false;
% See whether or not the block is a Support Package System Block
i = strcmp(block_type, blks(:,1)); 

if ~any(i)
    mapName = 'User Defined';
else
    px4DocRoot =  codertarget.internal.px4.getDocRoot;
	relativePathToMapFile = fullfile(px4DocRoot, 'helptargets.map');
	found = 'fullpath';
    mapName = blks(i,2);
end

