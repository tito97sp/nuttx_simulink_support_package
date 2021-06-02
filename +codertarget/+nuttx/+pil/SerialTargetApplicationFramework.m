classdef SerialTargetApplicationFramework < rtw.pil.RtIOStreamApplicationFramework
%TARGETAPPLICATIONFRAMEWORK is an example target connectivity configuration class
    
%   Copyright 2007-2018 The MathWorks, Inc.
    
    methods
        function this = SerialTargetApplicationFramework(componentArgs)
            narginchk(1, 1);
            % call super class constructor
            this@rtw.pil.RtIOStreamApplicationFramework(componentArgs);
            
            % get configset
            hCS = componentArgs.getConfigInterface.getConfig;
            SrcPath = fullfile(...
                codertarget.nuttx.internal.getSpPkgRootDir, ...
                'src');
            IncPath = fullfile(...
                codertarget.nuttx.internal.getSpPkgRootDir, ...
                'include');
            
            buildInfo = this.getBuildInfo;
            % Add header paths to buildinfo
            buildInfo.addIncludePaths(IncPath);
            % Add PIL main to builinfo
            buildInfo.addSourceFiles('pil_main_nuttx.cpp',fullfile(SrcPath));
            % Add any additional files specific to Nuttx PIL
            buildInfo.addSourceFiles('MW_Nuttx_rtiostream_serial.cpp',fullfile(SrcPath));
            buildInfo.addSourceFiles('MW_Nuttx_TaskControl.cpp',fullfile(SrcPath));
            buildInfo.addSourceFiles('nuttxinitialize.cpp',fullfile(SrcPath));
            % Add Nuttx specific defines to buildinfo
            buildInfo.addDefines('PIL');                        
            buildInfo.addDefines('RTIOSTREAM_RX_BUFFER_BYTE_SIZE=128');
            buildInfo.addDefines('RTIOSTREAM_TX_BUFFER_BYTE_SIZE=128');        
            
            %[BaudRate,COMPort] = codertarget.pixhawk.internal.getPILInfo(hCS);
            %buildInfo.addDefines(['MW_NUTTX_EXTMODE_BAUD_RATE=',BaudRate]);
            %buildInfo.addDefines(['MW_NUTTX_EXTMODE_HWPORT="',COMPort,'"']);
            
            % Hardcoded by the moment.
            buildInfo.addDefines(['MW_NUTTX_EXTMODE_BAUD_RATE=',11500]);
            buildInfo.addDefines(['MW_NUTTX_EXTMODE_HWPORT="','/dev/ttyACM0','"']);

            % Add link objects
            tgtAttributes = codertarget.attributes.getTargetHardwareAttributes(hCS);
            linkObjs = tgtAttributes.getLinkObjects();
            for i=1:length(linkObjs)
                name = codertarget.utils.replaceTokens(hCS, linkObjs{i}.Name, tgtAttributes.Tokens);
                path = codertarget.utils.replaceTokens(hCS, linkObjs{i}.Path, tgtAttributes.Tokens);
                buildInfo.addLinkObjects(name, path, 1000, true, true);
            end
        end
    end
end
