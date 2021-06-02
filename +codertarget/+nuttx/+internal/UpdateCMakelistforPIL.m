function UpdatePX4CMakelistforPIL(buildInfo)

%   Copyright 2019 The MathWorks, Inc.


% By default, findIncludeFiles errors out if finds an unknown
% header ignoreParseError converts the errors into warnings
% ignoreMissingIncludes suppresses the warnings.
findIncludeFiles(buildInfo, ...
    'extensions', {'*.h' '*.hpp'}, ...
    'ignoreParseError', true, ...
    'ignoreMissingIncludes', true);

% Grab list of all files to export
FullfilePaths_List = getFullFileList(buildInfo);
FullfilePathsFiltered_List = [];

for i = 1:numel(FullfilePaths_List)
    [~, ~, ext] = fileparts(FullfilePaths_List{i});
    if strcmp(ext,'.c') || strcmp(ext,'.cpp') || strcmp(ext,'.s') || strcmp(ext,'.lib') || strcmp(ext,'.a') || strcmp(ext,'.h') || strcmp(ext,'.hpp')
        FullfilePathsFiltered_List{end+1} = FullfilePaths_List{i}; %#ok<AGROW>
    end
end

SimulinkAppDir = fullfile(nuttx.internal.util.CommonUtility.getNuttxFirmwareDir, 'src','modules', buildInfo.ModelName + '_PIL');
%SimulinkAppDir = fullfile(codertarget.nuttx.internal.getBaseDir,'Firmware', 'src','modules','px4_simulink_app');

% CMAKE Creation
updateCMakeListsTxt(buildInfo,...
    FullfilePathsFiltered_List, SimulinkAppDir);

if (exist(SimulinkAppDir, 'dir') == 0)
    [~, ~, ~] = mkdir(SimulinkAppDir);
end

for FileIdx = 1:length(FullfilePathsFiltered_List)
    copyfile(FullfilePathsFiltered_List{FileIdx}, SimulinkAppDir, 'f') ;
end
end

%--------------------------------------------------------------------------
% Internal functions
%--------------------------------------------------------------------------
function updateCMakeListsTxt(buildInfo,SRCFIleList, cmakeListPath)

fileID = fopen(fullfile(cmakeListPath,'CMakeLists.txt'));
% Store the entire contents of the CMAKELIST File in cmakeListArray
cmakeListArray = textscan( fileID, '%s', 'Delimiter','\n', 'CollectOutput',true );
cmakeListArray = cmakeListArray{1};
fclose(fileID);

% Find the Line number where 'add_definitions('
% is in the CMAKE File
defIndex = find(contains(cmakeListArray,'add_definitions('), 1);

% Using the String Writer class created for writing
% CMAKELists.txt
hs = StringWriter;

if ~isempty(defIndex)
    % Copy the lines from the original CMAKE file as it is
    % till the line containing 'set(config_module_list'
    for i=1:defIndex
        hs.addcr(cmakeListArray{i});
    end

    % Add PIL specific definitions to cmakeList
    def = buildInfo.getDefines;
    if ~isempty(def)   
        for k = 1:numel(def)
            %add the defines only if it is not present
            if ~contains(cmakeListArray{defIndex+1},def{k})
                hs.add(def{k});
                hs.add(' ');
            end
        end
    end
    
    %copy the existing def 
    hs.add(cmakeListArray{defIndex+1});
    hs.addcr();
else
    defIndex = -1;
end

% Find the Line number where 'SRCS'
% is in the CMAKE File
srcIndex = find(contains(cmakeListArray,'SRCS'), 1);

if ~isempty(srcIndex)
    % Copy the lines from the original CMAKE file as it is after the defines 
    % till the line containing 'SRCS'
    for i=defIndex+2:srcIndex
        hs.addcr(cmakeListArray{i});
    end

    % Add PIL specific src to cmakeList
    if ~isempty(SRCFIleList)   
        for k = 1:numel(SRCFIleList)
            [~, name, ext] = fileparts(SRCFIleList{k});
            srcFileName = sprintf('%s', [name, ext]);
            %add the source files only if it is not present
            if isempty(find(contains(cmakeListArray,srcFileName), 1))
                if(~isequal('ert_main.cpp', cmakeListArray{i}))
                    hs.addcr(srcFileName);
                end
            end
        end
    end
else
    srcIndex = 0;
end

% Copy the lines from the original CMAKE file as it is
% till the end
for i = srcIndex+1:length(cmakeListArray)
    if(~isequal('ert_main.cpp', cmakeListArray{i}) && ...
            ~isequal('coder_profile_timer.cpp', cmakeListArray{i})&&...
           ~isequal('coder_profile_timer.h', cmakeListArray{i}) && ...
           ~isequal('MW_custom_RTOS_header.h', cmakeListArray{i}))  
        hs.addcr(cmakeListArray{i});
    end
end

hs.write(fullfile(cmakeListPath,'CMakeLists.txt'));
end

% LocalWords:  px hwsetup FW reinit Abt pixhawk CMAKE
% LocalWords:  thirdparty PTool codertarget
% LocalWords:  px hwsetup FW reinit Abt pixhawk CMAKE CMakeLists mnt
% LocalWords: Toolchain utils CXX Werror Wno fpermissive cmakelist
% LocalWords:  thirdparty PTool codertarget EXTMODE ROOTDIR CMake