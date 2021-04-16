classdef PX4MakefileBuilder < rtw.connectivity.MakefileBuilder
    %PX4MAKEFILEBUILDER builds px4 application for a pixhawk target
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    
    methods
        % constructor
        function this = PX4MakefileBuilder(componentArgs, ...
                targetApplicationFramework, ...
                exeExtension)
            
            % call super class constructor
            this@rtw.connectivity.MakefileBuilder(componentArgs, ...
                targetApplicationFramework, exeExtension);
            
            
        end
    end
    
    
    methods (Access = 'protected')
        function build(this, buildInfo, lXilCompInfo, varargin)
            
            componentCodePath = this.getComponentArgs.getComponentCodePath;
            
            % this is a workaround for modelref PIL
            if(contains(componentCodePath,'instrumented') )
                
                if(~exist(fullfile(componentCodePath,[buildInfo.ModelName,'.cpp']),'file'))
                    fd = fopen(fullfile(componentCodePath,[buildInfo.ModelName,'_rtwlib.mk']),'w');
                    fclose(fd);
                end
                
            end
			% this is workaround for issue g2286007 - PIL fails for rebuild (when the generated code already exists)
            % creating dummy .o files of model specific files.
            for idx=1:length(buildInfo.ModelRefs)
                fd = fopen(fullfile(componentCodePath,buildInfo.ModelRefs(idx).Name),'w');
                fclose(fd);
            end
            %this is a workaround for profiler - model specific files are added as modelref libraries.
            %this creates error while doing getFullFileList(buildInfo)
            buildInfo.ModelRefs =[];
            
            % call super class constructor
            this.build@rtw.connectivity.MakefileBuilder(buildInfo, lXilCompInfo, varargin{:})
            
            %update CMAKELIST for PIL
            codertarget.pixhawk.internal.UpdatePX4CMakelistforPIL(buildInfo);
            
            %px4 build command
            if ispc
                [status, msg] = system([fullfile(codertarget.pixhawk.internal.getPX4CygwinDir,'run-console_Simulink.bat'),' "',...
                    'cd ',strrep(fullfile(codertarget.pixhawk.internal.getPX4BaseDir,'Firmware'), '\','/'),...
                    '; make ',codertarget.pixhawk.internal.getPX4CmakeConfig, '"'],'-echo');
            elseif isunix
                % Correct the python path. Added for a python path issue in Linux
                currentEnvPath = getenv('LD_LIBRARY_PATH');
                if ~contains(currentEnvPath, '/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu:')
                    setenv('LD_LIBRARY_PATH',['/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu:' currentEnvPath])
                end
                
                [status, msg] = system(['cd ',fullfile(codertarget.pixhawk.internal.getPX4BaseDir,'Firmware'),...
                    '&& /usr/bin/make ',codertarget.pixhawk.internal.getPX4CmakeConfig],'-echo');
                
                % Remove added python library from MATLAB path
                newEnvPath = erase(currentEnvPath, '/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu:');
                setenv('LD_LIBRARY_PATH', newEnvPath)
            end
            
            if(status)
                error(message('px4:cgen:PX4BuildError', msg).getString);
            end
            
            %copy px4 file to the rtw pil folder
            pilFolder = this.getComponentArgs.getApplicationCodePath;
            ConfigCMake = codertarget.pixhawk.internal.getPX4CmakeConfig;
            firmwareImagePath = fullfile(px4.internal.util.CommonUtility.getPX4FirmwareBuildDir ,[ConfigCMake,'.px4']);
            copyfile(firmwareImagePath,pilFolder, 'f');
            %rename the px4 application to [model name].px4
            movefile(fullfile(pilFolder,[ConfigCMake,'.px4']),fullfile(pilFolder,[buildInfo.ModelName,'.px4']))
            
        end
        
    end
    
end
