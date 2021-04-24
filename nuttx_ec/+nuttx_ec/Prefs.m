classdef Prefs
%PREFS gives access to Nuttx EC preferences file
%
%   This is an undocumented class. Its methods and properties are likely to
%   change without warning from one release to the next.
%
%   Copyright 2009-2014 The MathWorks, Inc.

    methods (Static, Access=public)
%%
        function setPILSpeed(speed)
            nuttx_ec.Prefs.setPref('PILSpeed', speed);
        end

%%
        function speed = getPILSpeed
            speed = nuttx_ec.Prefs.getPref('PILSpeed');
            if isempty(speed)
                speed = 9600;    % take default speed
            end
        end
%%
        function setNuttxPath(toolPath)

            if ~exist('toolPath', 'var') || ~ischar(toolPath)
               nl = sprintf('\n');
               error('RTW:nuttx_ec:invalidNuttxPath', ...
                      ['Nuttx path must be a string, e.g.' nl ...
                       '   nuttx_ec.Prefs.setNuttxPath(''c:\\nuttx-1.0.5'')']);
            end

            if ~exist(toolPath,'dir')
                error('RTW:nuttx_ec:invalidNuttxPath', 'The specified folder (%s) does not exist', toolPath);
            end

            if ~exist(fullfile(toolPath, 'nuttx.exe'), 'file')
                error('RTW:nuttx_ec:invalidNuttxPath', 'The specified folder (%s) does not contain nuttx.exe', toolPath);
            end

            % remove trailing backslashes
            toolPath = regexprep(toolPath, '\\+$', '');

            % Alternate form of path to handle spaces
            altPath = RTW.transformPaths(toolPath, 'pathType', 'alternate');

            nuttx_ec.Prefs.setPref('NuttxPath', altPath);

            % The board data is tied to a specific version of Nuttx IDE, so if we change
            % the Nuttx path (possibly to a different IDE) the existing data may not be valid
            nuttx_ec.Prefs.setPref('NuttxBoard', []);

            nuttx_ec.Prefs.setPref('NuttxBoardName', '');
        end

%%
        function toolPath = getNuttxPath
            toolPath = nuttx_ec.Prefs.getPref('NuttxPath');
            % check validity of path (in case the folder got deleted between
            % after setNuttxPath and before getNuttxPath)
            if ~exist(toolPath,'dir')
                nl = sprintf('\n');
                error('RTW:nuttx_ec:invalidNuttxPath', ...
                      ['Nuttx path is unspecified or invalid.' nl ...
                       'Specify a valid path using nuttx_ec.Prefs.setNuttxPath, e.g.' nl ...
                       '   nuttx_ec.Prefs.setNuttxPath(''c:\\nuttx-1.0.5'')']);
            end
        end

%%
        function setBoard(boardLabel)
            boardsFile = fullfile(nuttx_ec.Prefs.getNuttxPath(), 'hardware', 'nuttx', 'boards.txt');

            if ~exist(boardsFile, 'file')
                nl = sprintf('\n');
                error('RTW:nuttx_ec:invalidNuttxPath', ...
                      ['Unable to find board specification file. Ensure that' nl ...
                       'the path to the Nuttx IDE is set correctly, e.g.' nl ...
                       '  nuttx_ec.Prefs.setNuttxPath(''c:\nuttx-1.0.5'')'] );
            end
            boards = nuttx_ec.Prefs.parseBoardsFile(boardsFile);
            if isempty(boards)
                error('RTW:nuttx_ec:invalidBoardSpecification', ...
                      'Unable to read board specification file (%s)', boardsFile);
            end
            
            parsedLines = regexp(boards, ['^(', boardLabel, '\..+)=([^$]+)$'],'tokens');
            % parsedLines = regexp(rawLines,'^([^=]+)=([^$]+)$','tokens');

            specifiedBoard = {};
            ind = 0;
            for i=1:numel(parsedLines)
                if ~isempty(parsedLines{i})
                    ind = ind + 1;
                    specifiedBoard(ind) = parsedLines{i};
                end
            end

            if isempty(specifiedBoard)
                msg = 'Specified board not found in configuration file';
                error('RTW:nuttx_ec:invalidBoardLabel', msg);
            end
            nuttx_ec.Prefs.setPref('NuttxBoard', specifiedBoard);
            nuttx_ec.Prefs.setPref('NuttxBoardName', boardLabel);
        end

%%
        function [boardLabel, allData] = getBoard
            boardLabel = nuttx_ec.Prefs.getPref('NuttxBoardName');
            board = nuttx_ec.Prefs.getPref('NuttxBoard');
            if isempty(board)
                nl = sprintf('\n');
                error('RTW:nuttx_ec:noBoardSpecification', ...
                      ['Nuttx board is not yet specified. ' nl ...
                       'Specify the board using nuttx_ec.Prefs.setBoard, e.g.' nl ...
                       '  nuttx_ec.Prefs.setBoard(''uno'') ']);
            end
            if nargout == 2
                allData = board;
            end
        end
%%
        function mcu = getMCU
            mcu = nuttx_ec.Prefs.getKey('mcu');
        end
%%
        function cpu = getCPU
            cpu = nuttx_ec.Prefs.getKey('cpu');
        end
%%
        function uploadRate = getUploadRate
            uploadRate = nuttx_ec.Prefs.getKey('upload.speed$');
        end
%%
        function ret = getKey(key)
            [~, board] = nuttx_ec.Prefs.getBoard;
            ret = '';
            key = regexprep(key, '\.', '\\.');
            for i=1:numel(board)
                found = regexp(board{i}{1}, ['.*\.' key]);
                if found
                    ret = board{i}{2};
                    return
                end
            end
        end
%%
        function programmer = getProgrammer
            programmer =  nuttx_ec.Prefs.getKey('protocol');
        end
%%
        function cpu_freq = getCpuFrequency
            cpu_freq = nuttx_ec.Prefs.getKey('f_cpu');
        end
%%
        function port = getComPort
            port = nuttx_ec.Prefs.getPref('ComPort');
            if isempty(port)
                nl = sprintf('\n');
                msg = [
                    'The Nuttx serial port must be set and you must have installed' nl ...
                    'the device drivers for your Nuttx hardware. ' nl ...
                    ' 1. Install the drivers and connect the Nuttx hardware. ' nl ...
                    ' 2. Identify the virtual serial (COM) port. You can do this through' nl ...
                    '    the Windows Device Manager, or by running nuttx_ec.Prefs.setComPort' nl ...
                    ' 3. Set the correct COM port using nuttx_ec.Prefs.setComPort' ...
                    ];
                error('RTW:nuttx_ec:invalidComPort', msg);
            end
        end
%%
        function setComPort(port)
            if ~exist('port', 'var') || ~ischar(port) || isempty(port)
                nl = sprintf('\n');
                error('RTW:nuttx_ec:invalidComPort', ...
                      ['Specify the COM port as a string. E.g.: ' nl ...
                       '   nuttx_ec.Prefs.setComPort(''COM8'') ']);
            end
            nuttx_ec.Prefs.setPref('ComPort', port);
        end
%%
        function ports = searchForComPort(regCmdOutput)
            ports='';

            if ispc
                if nargin < 1
                    regCmd=['reg query '...
                        'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM'];
                    [~,regCmdOutput]=system(regCmd);
                end

                deviceName='\\Device\\(VCP\d|USBSER\d{3})';
                reg_sz = 'REG_SZ';
                portNum = 'COM\d+';
                expr = [deviceName '\s+' reg_sz '\s+(' portNum ')'];
                allPorts=regexp(regCmdOutput,expr,'tokens');
                if ~isempty(allPorts)
                    ports=cell(1, length(allPorts));
                    for j=1:length(allPorts)
                        ports{j}=allPorts{j}{2};
                    end
                end
            end
        end
    end
%%
    methods(Static,Access=private)

        function setPref(prefName, prefValue)
            prefGroup = 'NuttxGeneric';
            setpref(prefGroup, prefName, prefValue);
        end

        function prefValue = getPref(prefName)
            prefGroup = 'NuttxGeneric';
            if ispref(prefGroup,prefName)
                prefValue = getpref(prefGroup, prefName);
            else
                prefValue = '';
            end
        end

        function boards = parseBoardsFile(filename)
            boards = {};
            fid = fopen(filename, 'rt');
            if fid < 0,
                return;
            end
            txt = textscan(fid,'%s', 'commentstyle','#','delimiter','\n', 'multipledelimsasone',true);
            fclose(fid);
            boards = txt{1};
        end
    end
end

% LocalWords:  USBSER
