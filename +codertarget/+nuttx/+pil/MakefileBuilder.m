classdef MakefileBuilder < rtw.connectivity.MakefileBuilder
%PX4MAKEFILEBUILDER builds px4 application for a pixhawk target

%   Copyright 2019 The MathWorks, Inc.

    
    methods
        % constructor
        function this = MakefileBuilder(componentArgs, ...
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
            codertarget.nuttx.internal.UpdateCMakelistforPIL(buildInfo);
                       
            %build processs
            %hand-process by the moment.

          end
        
    end
    
end
% LocalWords: px pixhawk rtwlib CMAKELIST cgen pil usr linux
