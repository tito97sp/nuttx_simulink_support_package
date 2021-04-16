function onAfterCodeGen(hCS, buildInfo)

%

%   Copyright 2018-2021 The MathWorks, Inc.

    configOpts = codertarget.data.getData(hCS);
    if(isfield(configOpts, 'enableMavlinkCheckbox'))
        if ~(configOpts.enableMavlinkCheckbox) % If the MAVLink is not enabled in Config-set, disable it.
            buildInfo.addDefines('-DMW_PX4_DISABLE_MAVLINK=1'); % Add a #define to stop MAVLink
        end
    end

    targetHardware = hCS.get_param('HardwareBoard');

    if (isequal(targetHardware, 'PX4 Crazyflie 2.0') && ispref('MW_PX4_SIMULINK_ALGORITHM')) %Modules to disable, only for Crazyflie
        simulinkAlgorithm = getpref('MW_PX4_SIMULINK_ALGORITHM', 'AlgorithmType');
        if strcmp(simulinkAlgorithm, message('px4:hwsetup:SelectAlgorithm_PathFollower').getString)
            buildInfo.addDefines('-DMW_PX4_CRAZYFLIE_PATHFOLLOWER=1'); % Add a #define to stop modules related to Path Follower
        elseif strcmp(simulinkAlgorithm, message('px4:hwsetup:SelectAlgorithm_FlightController').getString)
            buildInfo.addDefines('-DMW_PX4_CRAZYFLIE_CONTROLLER=1');  % Add a #define to stop modules related to Controller
        end
    end

    if strcmp(get_param(hCS,'ExtMode'), 'on') && ~strcmp(targetHardware,  message('px4:hwinfo:PX4HostTarget').getString)
        [baudRate, hardwareSerialPortName] = codertarget.pixhawk.internal.getExternalModeInfo(hCS);
        buildInfo.addDefines(['-DMW_PX4_EXTMODE_BAUD_RATE=' num2str(baudRate) ]);
        %The old infrastructure used to resolve the double quotes. We need a
        %backslash for the infrastructure, else compilation fails
        buildInfo.addDefines(['-DMW_PX4_EXTMODE_HWPORT=\"' hardwareSerialPortName '\"']);

        if(isfield(configOpts, 'enableMavlinkCheckbox'))  % This field is only for Crazyflie as of now
            if ((configOpts.enableMavlinkCheckbox) && isequal(configOpts.ExtSerialPort,'/dev/ttyACM0')) % If both ext. mode and MAVLink use USB serial port, error out
                error(message('px4:general:mavlinkExtSerialConflict', configOpts.ExtSerialPort).getString);
            end
        end

        if ~coder.internal.xcp.isXCPOnSerialTarget(hCS)
            % This MACRO is used to distinguish between Classical and XCP
            % External Mode by logic in rtIOStreamRecv  to filter out spurious
            % bytes. We need to consider if this use case is still valid.
            buildInfo.addDefines('-DCLASSICAL_EXT_MODE');
        end
    end

    if coder.internal.xcp.isXCPOnTCPIPTarget(hCS) && ...
            strcmp(targetHardware,  message('px4:hwinfo:PX4HostTarget').getString)
        % This MACRO is used to distinguish Windows and Linux so that the
        % appropriate XCP_ADDRESS_GET gets defined in xcp_platform_custom.cpp
        % and the addresses are properly fetched depending on platform.
        if ispc
            buildInfo.addDefines('-D_MINGW_W64');
        elseif isunix && ~ismac
            buildInfo.addDefines('-D_GNU_LINUX');
        end
        % This MACRO increases the logging buffer size for PX4 Host Target and
        % avoids data drop at higher sampling frequency (1 ms).
        buildInfo.addDefines('-DXCP_MEM_DAQ_RESERVED_POOL_BLOCKS_NUMBER=100');
    end

    modelName = get_param(hCS.getModel, 'Name');
    if (strcmp(get_param(hCS,'MatFileLogging'),'on'))
        SrcFiles = buildInfo.Src.Files; %Get all source files and find rt_logging.c
        IndexLoggingFile = arrayfun(@(x)strcmp(x.FileName,'rt_logging.c'),SrcFiles); %Find rt_logging.c index
        SrcFiles(IndexLoggingFile) = []; %Remove rt_logging.c
        buildInfo.Src.Files = SrcFiles; % Update buildinfo after removing rt_logging.c
        size = codertarget.pixhawk.registry.staticMemorySizeforSDCard(modelName);

        loggingroot = strrep(matlabshared.file_logging.getRootDir(),'\','/');
        buildInfo.addIncludePaths(fullfile(loggingroot,'include'));
        sppkgroot=codertarget.pixhawk.internal.getSpPkgRootDir ;

        buildInfo.addSourceFiles('ert_targets_logging.c',fullfile(loggingroot,'src'), 'SkipForSil');
        buildInfo.addSourceFiles({'px4_file_logging.cpp'},fullfile(sppkgroot,'src'), 'SkipForSil');
        buildInfo.addDefines('-DMW_SD_STATIC_MEMORY_ENABLE', 'SkipForSil');
        buildInfo.addDefines(['-DMW_SD_VERBOSE_DISABLE=', num2str(1)], 'SkipForSil');
        buildInfo.deleteDefines('-DMW_SD_STATIC_MEMORY_SIZE');
        buildInfo.addDefines(['-DMW_SD_STATIC_MEMORY_SIZE=', num2str(size)], 'SkipForSil');
    end

    if strcmp(targetHardware,  message('px4:hwinfo:PX4HostTarget').getString)
        buildInfo.addDefines('-DPORTABLE_WORDSIZES');
    end

    px4.internal.cgen.postCodeGenHook(hCS, buildInfo);

    baseRate = getBaseRate(hCS.getModel);

    if baseRate < 0.001
        error(message('px4:cgen:UnsupportedBaseRate', num2str(baseRate*1000)).getString);
    end

    %for PIL
    modelCodegenMgr = coder.internal.ModelCodegenMgr.getInstance(getModel(hCS));
    xilInfo = modelCodegenMgr.MdlRefBuildArgs.XilInfo;
    isPIL = xilInfo.IsPil;

    if(isPIL)
        setenv('MW_PX4_isPIL','True');
        %get PIL target serial port
        if isfield(configOpts, 'PILHardwareSerialPort_Checkbox') &&(configOpts.PILHardwareSerialPort_Checkbox == 0)
            hardwareSerialPort = configOpts.PILSerialPort;
        else
            hardwareSerialPort = configOpts.ExtSerialPort;
        end
        %Target serialport conflict check with MAVLink
        if(isfield(configOpts, 'enableMavlinkCheckbox'))
            if ((configOpts.enableMavlinkCheckbox) && isequal(hardwareSerialPort,'/dev/ttyACM0')) % If MAVLink is enabled and PIL uses /dev/ttyACM0, error out
                error(message('px4:general:mavlinkPILSerialConflict', hardwareSerialPort).getString);
            end
        end
    else
        setenv('MW_PX4_isPIL','False');
    end

    px4SimulinkAppDir = fullfile(codertarget.pixhawk.internal.getPX4BaseDir,'Firmware', 'src','modules','px4_simulink_app');

    %first, clear out existing build directory for simulink app module
    if exist(px4SimulinkAppDir, 'file') > 0
        disp(message('px4:general:RemovePX4SLAppDirectory', px4SimulinkAppDir).getString);
        try
            delete([px4SimulinkAppDir filesep '*']) ;
        catch
            error(message('px4:general:RemovePX4SLAppDirectoryFailed', px4SimulinkAppDir).getString);
        end
    else
        disp(message('px4:general:NoPX4SLAppDirectory').getString);
    end


    % CMAKE Routine
    if (px4.internal.cgen.Util.isTopLevelModel(buildInfo)|| isPIL)
        if ispc
            codertarget.pixhawk.internal.CreatePX4CMakelistforCygwin(hCS,buildInfo);
        else
            codertarget.pixhawk.internal.CreatePX4CMakelist(hCS,buildInfo);
        end
        %Reset the back up logic environment variable
        setenv('MW_PX4_NewInfraBuildComplete','False');
        if(~isPIL)
            %Fast build infrastructure not supported for PIL

            %This is for internal purpose only. Use the below command to use the
            %old build infrastructure
            %>>setpref('MW_PX4_Build','FullFirmwareBuild',true);
            %To reset back to normal build, use the below command
            %>>setpref('MW_PX4_Build','FullFirmwareBuild',false)
            if ispref('MW_PX4_Build','FullFirmwareBuild')
                UseFullFirmwareBuild = getpref('MW_PX4_Build','FullFirmwareBuild');
            else
                UseFullFirmwareBuild = false;
            end

            %Use the new build infrastructure for fmu targets only, not Host
            %Target and crazyflie
            %The only condition where new infra will kick in is when
            %UseFullFirmwareBuild is false and cmakeConfig is not HostTarget
            %and cmakeConfig is not crazyflie
            cmakeConfig = codertarget.pixhawk.internal.getPX4CmakeConfig;
            if(~UseFullFirmwareBuild) && ~(strcmp(cmakeConfig,...
                                                  message('px4:hwinfo:PX4HostTargetCmakeDefault').getString)) && ~(strcmp(cmakeConfig,...
                                                                  message('px4:hwinfo:Crazyflie2_0CmakeDefault').getString))
                codertarget.pixhawk.internal.buildPX4SimulinkApp(buildInfo);
            end
        end
    end

    %% ------------------------------LOG DDUX DATA------------------------------
    try
        supportedTags = codertarget.pixhawk.internal.registration.getRegistrationTags();
        dduxObj = matlabshared.internal.SLSPKGUtility(supportedTags);
        dduxObj.dataUpdate(hCS,buildInfo.ComponentName);
        clear dduxObj;
    catch
        
    end
    
    if ~strcmp(targetHardware,message('px4:hwinfo:PX4HostTarget').getString)
        periph_name = 'Runtime';
        param_name = 'BuildAction';
        % Check if the desired autopilot is connected to host computer when Build,
        % load and run is enabled
        if isfield(configOpts, periph_name) && isfield(configOpts.(periph_name), param_name)
            if strcmp(configOpts.(periph_name).(param_name), "Build, load and run")
                codertarget.pixhawk.internal.checkIfAutopilotIsConnected(hCS, targetHardware);
            end
        end
    end
end

function rate = getBaseRate(mdl)
    ModelRates = get_param(mdl, 'SampleTimes');
    rate = ModelRates(1).Value(1);
end
