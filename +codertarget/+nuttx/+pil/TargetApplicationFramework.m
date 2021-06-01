classdef TargetApplicationFramework < rtw.pil.RtIOStreamApplicationFramework
%TARGETAPPLICATIONFRAMEWORK is an example target connectivity configuration class
    
%   Copyright 2007-2018 The MathWorks, Inc.
    
    methods
        function this = TargetApplicationFramework(componentArgs)
            narginchk(1, 1);
            % call super class constructor
            this@rtw.pil.RtIOStreamApplicationFramework(componentArgs);
            
            % To build the PIL application you must specify a main.c file.       
            % The following PIL main.c files are provided and can be             
            % added to the application framework via the "addPILMain"            
            % method:                                                            
            %                                                                    
            % 1) A main.c adapted for on-target PIL and suitable                 
            %    for most PIL implementations. Select by specifying              
            %    'target' argument to "addPILMain" method.                       
            %                                                                    
            % 2) A main.c adapted for host-based PIL such as the                 
            %    "mypil" host example. Select by specifying 'host'               
            %    argument to "addPILMain" method.                                
            this.addPILMain('host');                                             
            
            % Additional source and library files to include in the build        
            % must be added to the BuildInfo property                            
            
            % Get the BuildInfo object to update                                 
            buildInfo = this.getBuildInfo;                                       
            
            % Add device driver files to implement the target-side of the        
            % host-target rtIOStream communications channel                      
            rtiostreamPath = fullfile(matlabroot, ...                            
                                      'toolbox', ...                                 
                                      'coder', ...                                                                         
                                      'rtiostream', ...   
                                      'src', ...
                                      'rtiostreamtcpip');                        
            buildInfo.addSourcePaths(rtiostreamPath);                            
            buildInfo.addSourceFiles('rtiostream_tcpip.c');                      
            
            % If using the LCC compiler on PC we must explicitly add the
            % sockets library
            if ispc && componentArgs.usingLcc
                addLCCSocketsLib(buildInfo);
            end
        end
    end
end
