classdef NuttxWorkflow < matlab.hwmgr.internal.hwsetup.Workflow
    %   PX4Workflow - The base workflow class for PX4 Flight Stack
    %   hardware setup
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    properties
        % Properties inherited from Workflow class
        Name = 'Nuttx'
        FirstScreenID
        %HardwareInterface - Interface to the hardware callbacks
        HardwareInterface
    end
    
    properties(Constant)
        %Inherited Properties
        BaseCode = 'NUTTXAUTOPILOTS';
    end
    
    properties
        
        % Directory location where images required for the screens are
        % stored
        ResourcesDir
        
        %ShowExamples - Example display decision from user
        ShowExamples = true;
        
        % BoardName - Name of the board that user chooses, which will be
        % configured to work with the support package
        BoardName
        
        % Directory location where Firmware folder is present. Eg: C:\px4\Firmware
        Nuttx_Firmware_Dir
        
        % Base Directory location of PX4 Tool chain. Eg: C:\px4
        Nuttx_Base_Dir
        
        % Directory location of Simulink Modules App. Eg - C:\px4\Firmware\src\modules\px4_simulink_app
        
        Nuttx_Simulink_Module_Dir
        
        % Build Directory location of Firmware. Eg - C:\px4\Firmware\build\px4_fum-v2_default
        
        Nuttx_Build_Dir
        
        % CMake Vendor eg- in px4_fmu-v2_default px4 is vendor
        
        CMakeVendor
        
        % CMake model  eg- in px4_fmu-v2_default fmu-v2 is model
        
        CMakeModel
        
        % CMake variant  eg- in px4_fmu-v2_default default is variant
        
        CMakeVariant
        
        % CMake file name (excludes the .cmake extension)
        Nuttx_Cmake_Config
        
        %To know if Toolchain is installed or not.
        ToolchainInstalled = codertarget.pixhawk.internal.GccVersion.NotInstalled;
        
        % Map object which contains the config files corresponding to the
        % board
        %----------------------------------------------------------------
        %---------Board---------------------Build Target-----------------
        %     1. PX4 Host Target     |   { px4_sitl_default }
        %     2. Pixhawk 1                |   { px4_fmu-v2_default
        %                                            , px4_fmu-v2_fixedwing
        %                                            , px4_fmu-v2_multicopter
        %                                            , px4_fmu-v2_rover
        %                                            , px4_fmu-v2_lpe,
        %                                            , px4_fmu-v3_default }
        %     3. Pixhawk 2.1             |   { px4_fmu-v3_default }
        %     4. Pixracer                 |   { px4_fmu-v4_default }
        %     5. Pixhawk 4               |   { px4_fmu-v5_default
        %                                            , px4_fmu-v5_fixedwing
        %                                            , px4_fmu-v5_multicopter
        %                                            , px4_fmu-v5_rover }
        %     6. Crazyflie 2.0           |   { bitcraze_crazyflie_default}
        %------------------------------------------------------------------
        BoardConfigMap
        
        %Cell array of supported boards
        Boards
        
        %To know if the user has selected Custom CMAKE Config or not
        isCustomConfig = false
        
        %Variable to hold the value of Current Date time of when the build
        %is started. This variable is shared between BuildPX4Firmware and
        %TestConnection screen.
        BuildTimeStamp
        
        %Variable to know if Build was performed or skipped
        BuildExecuted = [];
        
        %Variable to know if Firmware was uploaded successfully or not
        FirmwareUploaded = false;
        
        %Variable to know the OS and Platform
        Platform
        
        %Variable to hold the DFU utility for Crazyflie
        STM32_DFU_dir
    end
    
    properties (Constant)
        GITURLVALUE = 'https://github.com/PX4/Firmware.git';
        GITTAG = 'v1.10.2';
        CYGWIN_TOOLCHAIN_VERSION = 'v0.8';
        LOGFILE = fullfile(tempdir,'MW_px4_log.txt');
        SUPPORTED_GCC_WIN64 = "7.3.1"
        SUPPORTED_GCC_UBUNTU_1804 = "7.2.1"
    end
    
    % methods
    %     % Class Constructor
    %     function obj = NuttxWorkflow(varargin)
    %         % PX4Workflow - The Workflow class constructor creates
    %         % Workflow object for the PX4 Flight Stack Hardware Setup App.
    %         %
    %         % Call base class
            
    %         obj@matlab.hwmgr.internal.hwsetup.Workflow(varargin{:})
    %         obj.Name = message('Nuttx:hwsetup:WorkflowName').getString;
    %         obj.ResourcesDir = fullfile(codertarget.pixhawk.internal.getSpPkgRootDir, 'resources');
    %         obj.ShowExamples = true;
            
    %         p = inputParser;
    %         addParameter(p, 'hardwareInterface', []);
    %         % Ignore parameters defined by the base class
    %         p.KeepUnmatched = true;
    %         p.parse(varargin{:});
    %         obj.HardwareInterface = p.Results.hardwareInterface;
            
    %         if isempty(obj.HardwareInterface)
    %             obj.HardwareInterface = codertarget.pixhawk.hwsetup.HardwareInterface.getInstance(obj);
    %         end
            
    %         obj.Platform = codertarget.pixhawk.hwsetup.Platform.getOSPlatformDetails();
    %         obj.FirstScreenID = obj.getFirstScreenID();
            
    %         obj.Boards = {
    %             message('px4:hwinfo:PX4HostTarget').getString,...
    %             message('px4:hwinfo:Pixhawk1').getString,...
    %             message('px4:hwinfo:Pixhawk2').getString,...
    %             message('px4:hwinfo:PixRacer').getString,...
    %             message('px4:hwinfo:Pixhawk4').getString,...
    %             message('px4:hwinfo:Crazyflie2_0').getString,...
    %             message('px4:hwinfo:CustomBoard').getString,...
    %             };
    %         configs = {
    %             { message('px4:hwinfo:PX4HostTargetCmakeDefault').getString },...
    %             { message('px4:hwinfo:Pixhawk1CmakeDefault').getString,...
    %             message('px4:hwinfo:Pixhawk1CmakeFixedWing').getString,...
    %             message('px4:hwinfo:Pixhawk1CmakeMulticopter').getString,...
    %             message('px4:hwinfo:Pixhawk1CmakeRover').getString,...
    %             message('px4:hwinfo:Pixhawk1CmakeLPE').getString,...
    %             message('px4:hwinfo:Pixhawk2CmakeDefault').getString},...
    %             {message('px4:hwinfo:Pixhawk2CmakeDefault').getString},...
    %             {message('px4:hwinfo:PixracerCmakeDefault').getString},...
    %             { message('px4:hwinfo:Pixhawk4CmakeDefault').getString,...
    %             message('px4:hwinfo:Pixhawk4CmakeFixedWing').getString,...
    %             message('px4:hwinfo:Pixhawk4CmakeMulticopter').getString,...
    %             message('px4:hwinfo:Pixhawk4CmakeRover').getString},...
    %             {message('px4:hwinfo:Crazyflie2_0CmakeDefault').getString},...
    %             {[]},...
    %             };
            
    %         obj.BoardConfigMap = containers.Map(obj.Boards,configs,'UniformValues',false);
    %     end%end of PX4Workflow method
        
    % end %End of methods
    
    % methods (Access = private)
    %     function out = getFirstScreenID(obj)
            
    %         switch obj.Platform
    %             case codertarget.pixhawk.internal.OSPlatform.Windows
    %                 out = 'codertarget.pixhawk.hwsetup.SetupCygwinToolchain';
                    
    %             case codertarget.pixhawk.internal.OSPlatform.Ubuntu
    %                 out = 'codertarget.pixhawk.hwsetup.DownloadPX4';
                    
    %             case {codertarget.pixhawk.internal.OSPlatform.macOS,...
    %                     codertarget.pixhawk.internal.OSPlatform.Others}
    %                 out = 'codertarget.pixhawk.hwsetup.ErrorScreen';
    %         end
    %     end
    % end
    
end
