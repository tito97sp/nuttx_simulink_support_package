function setupBuildEnvironment()

%

%   Copyright 2018-2020 The MathWorks, Inc.

if isunix && ~ismac
    % Add python library to MATLAB path
    currentEnvPath = getenv('LD_LIBRARY_PATH');
    if ~contains(currentEnvPath, '/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu:')
        setenv('LD_LIBRARY_PATH',['/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu:' currentEnvPath])
    end
    % Add gcc 7.2 to MATLAB path
    systemPath = getenv('PATH') ;
    [~, homeFolder] = system('echo $HOME') ;
    if ~contains(systemPath , 'gcc-arm-none-eabi-7-2017-q4-major/bin')
        systemPath = [strip(homeFolder) '/gcc-arm-none-eabi-7-2017-q4-major/bin:' systemPath] ;
        setenv('PATH', systemPath);
    end
end

if ispc
    % use Cygwin toolchain to build Firmware in Windows
    setenv('MW_PX4_BUILDCMD', '$(CYGWINROOTDIR)/run-console_Simulink.bat "cd $(PX4FIRMWAREROOTDIR)/Firmware; make $(CMAKEMAKECONFIG)"') ;
else
    % build command for Linux and macOS
    setenv('MW_PX4_BUILDCMD', '/usr/bin/make $(CMAKEMAKECONFIG) ');
end

%for PIL
isPIl = getenv('MW_PX4_isPIL');

%fall back option for Old build infrastructure
isNewInfra = getenv('MW_PX4_NewInfraBuildComplete');

if(isequal(isPIl,'True') || isequal(isNewInfra,'True'))
    setenv('MW_PX4_BUILDCMD', 'echo ') ;
end
end
