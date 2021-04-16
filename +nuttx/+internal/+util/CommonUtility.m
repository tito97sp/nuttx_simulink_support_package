classdef CommonUtility
%   Utility functions that are used internally by the nuttx

%   Copyright 2018-2020 The MathWorks, Inc.

    methods (Static)
        function assigninGlobalScope(model, varName, varValue)
        %This function is for internal use only. It may be removed in the future.

        %ASSIGNINGLOBALSCOPE Assign value to variable
        %   If the MODEL input is empty, the expression will always be assigned in the
        %   base workspace. Otherwise, the expression will be passed along to the
        %   assigninGlobalScope function.

            if isempty(model)
                % Always assign in base workspace
                assignin('base', varName, varValue);
            else
                % Pass expression to standard assigninGlobalScope function
                assigninGlobalScope(model, varName, varValue);
            end
        end

        function varargout = evalinGlobalScope(model, exprToEval)
        %This function is for internal use only. It may be removed in the future.

        %EVALINGLOBALSCOPE Evaluate expression in global scope
        %   If the MODEL input is empty, the expression will always be evaluated in the
        %   base workspace. Otherwise, the expression will be passed along to the
        %   evalInGlobalScope function.

            if isempty(model)
                % Always evaluate in base workspace
                [varargout{1:nargout}] = evalin('base', exprToEval);
            else
                % Pass expression to standard evalinGlobalScope function
                [varargout{1:nargout}] = evalinGlobalScope(model, exprToEval);
            end
        end

        function varExists = existsInGlobalScope(model, varName)
        %This function is for internal use only. It may be removed in the future.

        %EXISTSINGLOBALSCOPE Check for existence of variable in global scope
        %   If the MODEL input is empty, the existence will be checked in the
        %   base workspace. Otherwise, the variable existence will be queried in
        %   the global scope through the existsInGlobalScope function.

            if isempty(model)
                % Always evaluate in base workspace
                varExists = evalin('base',['exist(''',varName,''',''var'');']) == 1;
            else
                % Pass expression to standard existsInGlobalScope function
                varExists = logical(existsInGlobalScope(model, varName));
            end
        end

        function baseDir = getNuttxFirmwareDir()
            baseDir = '/home/asanchez/Escritorio/GIT/project_template';
            if isempty(baseDir)
                nuttx.internal.util.CommonUtility.localizedError('nuttx:cgen:NuttxBaseDirEmpty');
            end
        end

        function modelMatFiles = getMATFilesForModel(allMATFiles,ModelName)
            ext = '.mat';
            %Get the indices of all files containing the model name
            indexModel = find(startsWith(allMATFiles,[ModelName,'_']));
            %Get the indices of all MAT Files
            indexMat = find(endsWith(allMATFiles,ext));
            if(isempty(indexModel) || isempty(indexMat))
                %Throw an appropriate error if the MAT Files corresponding to the Model
                %Name is not found on the SD card
                nuttx.internal.util.CommonUtility.localizedError('nuttx:general:MatFileNotFound',ModelName);
            end
            %Get indices of MAT Files corresponding to the ModelName
            modelMatFiles = allMATFiles(intersect(indexMat,indexModel));
        end

        function matFiles2Extract = extractLastRunMATFiles(modelMatFiles,ModelName)
        %Split all the cells with '_'
            splitcell = cellfun(@(x) strsplit(x,'_'),modelMatFiles,'UniformOutput',false);
            %Make a column cell with each row as the parts of split of <name_x_y>.mat
            splitcell = vertcat(splitcell{:});
            %Find the column corresponding to the runs (x)
            col = size(splitcell,2);
            %Find the last run
            runs = sort(unique(str2double(splitcell(:,col-1))));
            lastrun = runs(end);
            indexLastRun = contains(modelMatFiles,[ModelName,'_',num2str(lastrun)]);
            matFiles2Extract = modelMatFiles(indexLastRun);
        end

        function version = getNuttxFirmwareVersion()
            baseDir = nuttx.internal.util.CommonUtility.getNuttxFirmwareDir() ;
            FWDir = baseDir
            if ispc %Windows
                FWDir = codertarget.pixhawk.hwsetup.WindowsHardwareModule.convertWin2CygwinPath(FWDir);
                cygwinDir = codertarget.pixhawk.internal.getPX4CygwinDir;
                [st,verMsg] = system([fullfile(cygwinDir,'run-console_nuttx_fw_ver.bat'),' ','"',FWDir,'"']);
            else %Linux
                currDir = pwd;
                cd(FWDir);
                [st,verMsg] = system('git describe --tags');
                cd(currDir);
            end
            verMsgArray = splitlines(strip(verMsg));
            % In some PC, it has been that Cygwin bash shell
            % throws random warnings on launch which cause this
            % command to get messed up. Assumption is that the
            % the last value in the result is the desired result
            version = verMsgArray{end};
            if st
                error(message('nuttx:hwsetup:ValidatePX4_FWVerError',verMsg).getString);
            end
        end

        function boardRam = getBoardRAM(targetHardware)
        %This function returns the RAM for the board selected in the
        %Simulink Config settings
            boards = {
                message('nuttx:hwinfo:PX4HostTarget').getString,...
                message('nuttx:hwinfo:Pixhawk1').getString,...
                message('nuttx:hwinfo:Pixhawk2').getString,...
                message('nuttx:hwinfo:PixRacer').getString,...
                message('nuttx:hwinfo:Pixhawk4').getString,...
                message('nuttx:hwinfo:Crazyflie2_0').getString,...
                message('nuttx:hwinfo:PixhawkSeries').getString,...
                     };
            ram = {0,256,256,256,512,192,256};
            mapObj = containers.Map(boards,ram);
            boardRam = mapObj(targetHardware);
        end

        function configDir = getNuttxConfigDir()
            baseDir = nuttx.internal.util.CommonUtility.getNuttxFirmwareDir() ;
            configDir = fullfile(baseDir,'msg');
        end

        function buildDir = getNuttxFirmwareBuildDir()
            baseDir = nuttx.internal.util.CommonUtility.getNuttxFirmwareDir() ;
            %ConfigCMake = codertarget.pixhawk.internal.getNuttxCmakeConfig;
            %buildDir = fullfile(baseDir, 'build', ConfigCMake);
            buildDir = fullfile(baseDir, 'build');
        end

        function formatSpec = getNuttxMsgFormatSpec()
            formatSpec = '%s';
        end

        function localizedError(id, varargin)
        %There is a bug in MSLException which treats '\' as end of line
        %and hence does not consider any char after '\'. Therefore
        %replacing '\' with '\\'.
            msg = strrep(varargin,{'\'},{'\\'});
            e = MSLException([],id, getString(message(id, msg{:})));
            e.throw;
        end

        function localizedWarning(id, varargin)
        % Turn off backtrace for a moment

            sWarningBacktrace = warning('off', 'backtrace');
            warning(message(id, varargin{:}));
            warning(sWarningBacktrace);
        end

        function boards = getNuttxSupportedBoards()
        % Returns all the Hardware boards supported by PX4 HSP
            boards = {message('nuttx:hwinfo:Pixhawk1').getString,...
                      message('nuttx:hwinfo:Pixhawk2').getString,...
                      message('nuttx:hwinfo:PixRacer').getString,...
                      message('nuttx:hwinfo:Pixhawk4').getString,...
                     };
        end

        function COMPortFound = getCOMPort(board)

        % Use the serial port that is auto detected by MATLAB
        % Instantiate USBDeviceEnumerator class
            usbDevices = matlab.hwmgr.internal.hwconnection.USBDeviceEnumerator;
            COMPortFound = '';
            switch board
                % Pixhawk 1: Vendor ID: 26ac ; Product ID: 0011
              case {message('nuttx:hwinfo:Pixhawk1').getString}
                COMPortFound = usbDevices.getSerialPorts('productid','0011','vendorid','26ac');
                % Pixhawk 2 (Cube): Vendor ID: 26ac ; Product ID: 0011
              case {message('nuttx:hwinfo:Pixhawk2').getString}
                COMPortFound = usbDevices.getSerialPorts('productid','0011','vendorid','26ac');
                % Pixracer: Vendor ID: 26ac ; Product ID: 0012
              case {message('nuttx:hwinfo:PixRacer').getString}
                COMPortFound = usbDevices.getSerialPorts('productid','0012','vendorid','26ac');
                % Pixhawk 4: Vendor ID: 26ac ; Product ID: 0032
              case {message('nuttx:hwinfo:Pixhawk4').getString}
                COMPortFound = usbDevices.getSerialPorts('productid','0032','vendorid','26ac');
              case {message('nuttx:hwinfo:Crazyflie2_0').getString}
                COMPortFound = usbDevices.getSerialPorts('productid','0016','vendorid','26ac');
            end
        end

        function COMPort = verifyCOMPort(COMPortFound,board)
            if isempty(COMPortFound)
                nuttx.internal.util.CommonUtility.localizedError('nuttx:hwsetup:TestConn_BoardNotFound',board);
            elseif numel(COMPortFound) > 1
                switch(board)
                  case {message('nuttx:hwinfo:Pixhawk1').getString, ...
                        message('nuttx:hwinfo:Pixhawk2').getString}
                    nuttx.internal.util.CommonUtility.localizedError('nuttx:general:MultipleBoardsPixhawk1and2Detected');
                  case {message('nuttx:hwinfo:PixRacer').getString, ...
                        message('nuttx:hwinfo:Pixhawk4').getString}
                    nuttx.internal.util.CommonUtility.localizedError('nuttx:general:MultipleBoardsDetected',board);
                end
            end
            COMPort = char(COMPortFound);
        end

        function firmwareUploadCmd = getfirmwareUploadCmd(pythonApp,firmwareUploadScript,COM_PortToUse,firmwareImagePath, varargin)
            forceCmd = '';

            if ~isempty(varargin) && isequal(varargin{1},1)
                forceCmd =  ' --force';
            end

            firmwareUploadCmd = [pythonApp ' -u ' firmwareUploadScript forceCmd ' --port ' COM_PortToUse ' ' firmwareImagePath];
        end

        function CygwinPath = convertWin2CygwinPath(WinPath)
        %converting the windows path to Cygwin path
            WinPath = replace(WinPath,'\','/');
            WinPath(1)=lower(WinPath(1));
            DrvLetter = WinPath(1);
            CygwinPath = replace( (WinPath),[DrvLetter,':/'],['/cygdrive/',DrvLetter,'/']);
            %Replace any 'spaces' in path with '\ '
            %             CygwinPath = strrep(CygwinPath,' ','\ ');
        end%End of convertWin2CygwinPath method

    end
end
