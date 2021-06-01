classdef MakefileBuilder < rtw.connectivity.MakefileBuilder
%PX4MAKEFILEBUILDER builds px4 application for a pixhawk target

%   Copyright 2019 The MathWorks, Inc.

    
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

            %this is a workaround for profiler - model specific files are added as modelref libraries.
            %this creates error while doing getFullFileList(buildInfo)
            buildInfo.ModelRefs =[];
            
            % call super class constructor
            this.build@rtw.connectivity.MakefileBuilder(buildInfo, lXilCompInfo, varargin{:})
            
            %update CMAKELIST for PIL
            %codertarget.pixhawk.internal.UpdatePX4CMakelistforPIL(buildInfo);
            
            if(status)
                error(message('CMAKELIST creation');
            end
            
            %copy px4 file to the rtw pil folder
            %pilFolder = this.getComponentArgs.getApplicationCodePath;
            %ConfigCMake = codertarget.pixhawk.internal.getPX4CmakeConfig;
            %firmwareImagePath = fullfile(px4.internal.util.CommonUtility.getPX4FirmwareBuildDir ,[ConfigCMake,'.px4']);
            %copyfile(firmwareImagePath,pilFolder);
            %rename the px4 application to [model name].px4
            %movefile(fullfile(pilFolder,[ConfigCMake,'.px4']),fullfile(pilFolder,[buildInfo.ModelName,'.px4']))

          end
        
    end
    
end
% LocalWords: px pixhawk rtwlib CMAKELIST cgen pil usr linux
