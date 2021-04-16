function CreatePX4CMakelist(hCS,buildInfo)

%

%   Copyright 2018-2020 The MathWorks, Inc.

BuildStartDir_List = getBuildDirList(buildInfo);
if(~isempty(BuildStartDir_List))
    fprintf('Build path: %s \n',BuildStartDir_List{1})
end

% ignoreParseError converts parsing errors from findIncludeFiles into warnings
findIncludeFiles(buildInfo, ...
    'extensions', {'*.h' '*.hpp'}, ...
    'ignoreParseError', true);

IncludePathDir_List  = getIncludePaths(buildInfo,false)';

% Define start and build dir
sDir = getSourcePaths(buildInfo, true, {'StartDir'});
if isempty(sDir)
    sDir = {pwd};
end

% Replace $(MATLAB_ROOT) and $(START_DIR) in the build info with the
% real matlabroot and Start Directory

IncludePathDirFiltered_List = cellfun(@(x) strrep( x , '$(MATLAB_ROOT)', matlabroot),IncludePathDir_List,'UniformOutput', false) ;
IncludePathDirFiltered_List = cellfun(@(x) strrep( x , '$(START_DIR)', sDir{1}),IncludePathDirFiltered_List,'UniformOutput', false) ;
IncludePathDirFiltered_List = cellfun(@(x) strrep( x , '$(EXTMODE_DAEMON_SHARED_ROOTDIR)', matlabshared.externalmode_daemon.getDaemonRootDir),IncludePathDirFiltered_List,'UniformOutput', false) ;

% In case of Model reference, remove the path ../slprj
pathIndexToDelete = -1;
for i = 1:numel(IncludePathDirFiltered_List)
    if contains(IncludePathDirFiltered_List{i}, '..')
        pathIndexToDelete = i ;
    end
end
if (pathIndexToDelete > 0)
    IncludePathDirFiltered_List(pathIndexToDelete) = [];
end

% Grab list of all files to export
FullfilePaths_List = getFullFileList(buildInfo);
FullfilePathsFiltered_List = [];

for i = 1:numel(FullfilePaths_List)
    [~, ~, ext] = fileparts(FullfilePaths_List{i});
    if strcmp(ext,'.c') || strcmp(ext,'.cpp') || strcmp(ext,'.s') || strcmp(ext,'.lib') || strcmp(ext,'.a')
        FullfilePathsFiltered_List{end+1} = FullfilePaths_List{i}; %#ok<AGROW>
    end
end

% CMAKE Creation
writeCMakeListsTxt(hCS,...
    buildInfo,...
    IncludePathDirFiltered_List,...
    FullfilePathsFiltered_List);

% Add CMakeLists.txt to the list of files to be copied
FullfilePathsFiltered_List = [FullfilePathsFiltered_List, fullfile(pwd, 'CMakeLists.txt') ];

Destination_Dir = fullfile(codertarget.pixhawk.internal.getPX4BaseDir,'Firmware', 'src','modules','px4_simulink_app');

if (exist(Destination_Dir, 'dir') == 0)
    [~, ~, ~] = mkdir(Destination_Dir);
end

for FileIdx = 1:length(FullfilePathsFiltered_List)
    rc = copyfile(FullfilePathsFiltered_List{FileIdx}, Destination_Dir, 'f') ;
    if rc <= 0
        error(message('px4:general:CopyToPX4FolderFailed', Destination_Dir).getString);
    end
end

end

%--------------------------------------------------------------------------
% Internal functions
%--------------------------------------------------------------------------
function writeCMakeListsTxt(hCS,...
    buildInfo,...
    SL_IncludePaths,...
    SL_SrcFiles)

% Create string writer object
hs = StringWriter;

% Get Model Build Configuration
ConfigType = get_param(hCS,'BuildConfiguration');

if strcmp(ConfigType,'Specify')
    %If the user specified their own custom tool chain flags
    toolchainOptions = get_param(hCS,'CustomToolchainOptions') ;
    % C Compiler Flags
    if ~isempty(toolchainOptions{2})
        GetCurrentCFLAGS= textscan(toolchainOptions{2},'%s');
        GetCurrentCFLAGS =  cell(GetCurrentCFLAGS{1});
    else
        GetCurrentCFLAGS = {};
    end
    % C++ Compiler Flags
    if ~isempty(toolchainOptions{8})
        GetCurrentCppFLAGS= textscan(toolchainOptions{8},'%s');
        GetCurrentCppFLAGS =  cell(GetCurrentCppFLAGS{1});
    else
        GetCurrentCppFLAGS = {};
    end
    
    if ~isempty(toolchainOptions{4}) && ~isempty(toolchainOptions{10})
        % C Linker Flags
        GetCurrentCLinkerFLAGS= textscan(toolchainOptions{4},'%s');
        GetCurrentCLinkerFLAGS =  cell(GetCurrentCLinkerFLAGS{1});
        % C++ Linker Flags
        GetCurrentCppLinkerFLAGS= textscan(toolchainOptions{10},'%s');
        GetCurrentCppLinkerFLAGS =  cell(GetCurrentCppLinkerFLAGS{1});
        
        % Combined Linker Flags
        GetCurrentLinkerFLAGS = unique(vertcat(GetCurrentCLinkerFLAGS, GetCurrentCppLinkerFLAGS));
        GetCurrentLinkerFLAGS = strjoin(GetCurrentLinkerFLAGS);
    else
        GetCurrentLinkerFLAGS = '';
    end
end

% Header comments
hs.addcr('## This cmakelist.txt file was generated from');
hs.addcr('## the UAV Toolbox Support Package for PX4 Autopilots');
hs.addcr();

% Remove source file exemptions - external mode utils.c. Reason is because its not treated as an individual source file in build process
clcReturnVal = strfind(SL_SrcFiles,'ext_serial_utils');
for i=1:numel(clcReturnVal)
    if ~isempty(clcReturnVal{i})
        SL_SrcFiles(i) = []; %remove instance of this source file
    end
end

% Compiler defines generated from generated code

% Add project specific definitions
def = buildInfo.getDefines;
if ~isempty(def)
    hs.addcr('add_definitions(')
    for k = 1:numel(def)
        hs.add(def{k});
        hs.add(' ');
    end
    hs.addcr(')');
end
hs.addcr();

% Populate px4_add_module
hs.addcr('px4_add_module('); % Start of px4_add_module
hs.addcr(sprintf('    MODULE modules__%s','px4_simulink_app'));
hs.addcr(sprintf('    MAIN %s','px4_simulink_app'));
hs.addcr(sprintf('    STACK_MAIN %d',2000));
hs.addcr('SRCS');

% Add source files
for k = 1:numel(SL_SrcFiles)
    [~, name, ext] = fileparts(SL_SrcFiles{k});
    hs.addcr(sprintf('   %s', [name, ext]));
end

% Add compilation flags
compileFlags = {'-fpermissive', ...         % To relax the data-type conversions
    '-Wno-narrowing'};      % To allow narrowing conversions in bus structure
hs.addcr('    COMPILE_FLAGS');
for k = 1:numel(compileFlags)
    hs.addcr(sprintf('       %s', compileFlags{k}));
end

% Add the current directory for include
hs.addcr('    INCLUDES');
hs.addcr(sprintf('       %s', sprintf("${PX4_SOURCE_DIR}/src/modules/mavlink")));
hs.addcr(sprintf('       %s', sprintf("${PX4_SOURCE_DIR}/mavlink/include/mavlink")));

% Add include paths from generated code
if ~isempty(SL_IncludePaths)
    for k = 1:numel(SL_IncludePaths)
        hs.addcr(sprintf('       %s', SL_IncludePaths{k}));
    end
end
hs.addcr(')'); % End of px4_add_module
hs.addcr();

if strcmp(ConfigType,'Specify')
    % Insert CMAKE Flag over-ride here
    hs.addcr('# Over-ride compile flags here: ');
    hs.add('set(SL_CUSTOM_C_FLAGS ');
    hs.add(strjoin(GetCurrentCFLAGS));
    hs.addcr(')');
    hs.add('set(SL_CUSTOM_CPP_FLAGS ');
    hs.add(strjoin(GetCurrentCppFLAGS));
    hs.addcr(')');
    hs.add('set(SL_CUSTOM_LINKER_FLAGS ');
    hs.add(GetCurrentLinkerFLAGS);
    hs.addcr(')');
    hs.addcr();
    hs.addcr('set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SL_CUSTOM_C_FLAGS}")');
    hs.addcr('set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SL_CUSTOM_CPP_FLAGS}")');
    hs.addcr('set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${SL_CUSTOM_LINKER_FLAGS}")');
    hs.addcr();
end

if strcmp(ConfigType,'Faster Runs')
    hs.addcr('set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3")');
    hs.addcr('set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")');
    hs.addcr();
end

% Remove the Werror flag required for compilation
hs.addcr('get_target_property(PX4_SL_APP_COMPILE_FLAGS modules__px4_simulink_app COMPILE_OPTIONS)');
hs.addcr('list(REMOVE_ITEM PX4_SL_APP_COMPILE_FLAGS -Werror)');
hs.addcr('set_target_properties(modules__px4_simulink_app PROPERTIES COMPILE_OPTIONS "${PX4_SL_APP_COMPILE_FLAGS}")');
hs.addcr();

hs.write('CMakeLists.txt');
end
