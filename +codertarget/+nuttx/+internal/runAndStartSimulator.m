function runAndStartSimulator(hCS,executableFile,targetHardware,varargin)

%

%   Copyright 2019-2020 The MathWorks, Inc.
if strcmp(targetHardware,  message('px4:hwinfo:PX4HostTarget').getString)
    buildDir = px4.internal.util.CommonUtility.getPX4FirmwareBuildDir;
    
    % On Linux the Host Target executable is just 'px4' whereas  on Windows
    % MinGW generates 'px4.exe' as executable
    executableExtension = '';
    if ispc
        executableExtension = '.exe';
    end
    
    % Copy and rename the generated executable to be parsed by XCP External Mode
    % Target handler
    if coder.internal.xcp.isXCPOnTCPIPTarget(hCS)
        [exePath, exeName, ~] = fileparts(executableFile);
        % The executable name is dummy name '<modelName>.pre'. Replace '.pre'
        % with '.elf' to obtain destination elf Name as required by XCP
        elfName = [erase(exeName, '.pre') executableExtension];
        newELfPath = fullfile(exePath, elfName);
        generatedPX4Executable = fullfile(buildDir , 'bin', ['px4' executableExtension]);
        if isfile(generatedPX4Executable)
            copyfile(generatedPX4Executable, newELfPath);
        else
             error(message('px4:general:PX4ExecutableNotFound').getString);
        end
    end
    
    sitl = px4.internal.sitl.SimulationInTheLoop.getInstance();
    CoderTargetStruct = codertarget.data.getData(hCS);
    sitl.killSimulatorIfAlreadyOpen();
    % The jMavSim simulator is launched again after it is killed
    % off. Hence killing it again
    sitl.killSimulatorIfAlreadyOpen();
    
    if(strcmp(CoderTargetStruct.simulator,...
            message('px4:hwinfo:jMAVSim_Simulator').getString))
        
        % Launch jMAVSim simulator first
        sitl.startSimulatorForSITL();
        
        % Launch the host executable
        if ispc
            % In Windows, launch host executable with redirecting STDOUT.
            % The log file will have the Debug statements coming from Simulator
            % module which is added in HW setup screen for Windows
            launchHostExecutableAndRedirectSTDOUT(sitl, bdroot);
        elseif isunix && ~ismac
            % In Linux, we don't redirect STDOUT. The STDOUT does NOT
            % contain any Debug statements from Simulator module.
            launchHostExecutableWithoutRedirect(sitl);
        end
    else
        %Redirect the terminal output to a file as workaround for g2288658
        % Launch the Host Executable for Simulink plant always with
        % redirect both in Windows and Linux. Debug statements are added
        % for Windows but not for Linux
        launchHostExecutableAndRedirectSTDOUT(sitl, bdroot);
    end
end
end

function launchHostExecutableAndRedirectSTDOUT(sitlObj, modelName)
% Create a log file with model name
filename = fullfile(px4.internal.util.CommonUtility.getPX4FirmwareDir,[modelName,'.txt']);
filename = strrep(filename,'\','/');
sitlObj.startPX4HostExecutableWithRedirect(filename);
end

function launchHostExecutableWithoutRedirect(sitlObj)
sitlObj.startPX4HostExecutable();
end
