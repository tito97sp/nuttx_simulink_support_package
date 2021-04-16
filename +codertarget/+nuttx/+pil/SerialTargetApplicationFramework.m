classdef SerialTargetApplicationFramework < rtw.pil.RtIOStreamApplicationFramework
    %SERIALTARGETAPPLICATIONFRAMEWORK Serial application framework
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    methods
        % constructor
        function this = SerialTargetApplicationFramework(componentArgs)
            narginchk(1, 1);
            % call super class constructor
            this@rtw.pil.RtIOStreamApplicationFramework(componentArgs);
            
            % get configset
            hCS = componentArgs.getConfigInterface.getConfig;
            px4SrcPath = fullfile(...
                codertarget.pixhawk.internal.getSpPkgRootDir, ...
                'src');
            px4IncPath = fullfile(...
                codertarget.pixhawk.internal.getSpPkgRootDir, ...
                'include');
            
            buildInfo = this.getBuildInfo;
            % Add header paths to buildinfo
            buildInfo.addIncludePaths(px4IncPath);
            % Add PIL main to builinfo
            buildInfo.addSourceFiles('pil_main_px4.cpp',fullfile(px4SrcPath));
            % Add any additional files specific to PX4
            buildInfo.addSourceFiles('MW_PX4_rtiostream_serial.cpp',fullfile(px4SrcPath));
            buildInfo.addSourceFiles('MW_PX4_TaskControl.cpp',fullfile(px4SrcPath));
            buildInfo.addSourceFiles('nuttxinitialize.cpp',fullfile(px4SrcPath));
            % Add PX4 specific defines to buildinfo
            buildInfo.addDefines('PIL');
            buildInfo.addDefines('RTIOSTREAM_RX_BUFFER_BYTE_SIZE=128');
            buildInfo.addDefines('RTIOSTREAM_TX_BUFFER_BYTE_SIZE=128');
            [BaudRate,COMPort] = codertarget.pixhawk.internal.getPILInfo(hCS);
            buildInfo.addDefines(['MW_PX4_EXTMODE_BAUD_RATE=',BaudRate]);
            buildInfo.addDefines(['MW_PX4_EXTMODE_HWPORT="',COMPort,'"']);
            
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
