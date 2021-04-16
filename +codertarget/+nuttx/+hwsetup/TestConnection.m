classdef TestConnection < matlab.hwmgr.internal.hwsetup.VerifyHardwareSetup
    % TestConnection - This screen helps the user determine if the PC -
    % board setup is ready for Simulink Code generation.
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % ValidateEditText - Text box area to show install location that has
        % to be validated.
        ValidateEditText
        % BrowseButton - Button that on press opens a filesystem browser
        % for user to pick the correct install location.
        BrowseButton
        %Description text for the screen
        ScreenDescription
        % ConfigurationInstructions - Instructions for the user to help
        % them test their hardware connections
        ConfigurationInstructions
        % SelectionDropDown - Pop-up menu to display the list of items to choose
        % from (DropDown)
        SelectionDropDown
        % SelectionLabel - Text describing the category of the items in the
        % pop-up menu e.g. hardware, devices etc. (Label)
        SelectionLabel
        % COMPort - The COM Port to which the hardware board is connected
        COMPort
        % EditTextCOMPort - Text box area to show COM Port that has
        % to be validated.
        EditTextCOMPort
        % GetDataButton - Button that on press gets the Serial Data.
        GetDataButton
        % ReadEditText - Text box area to show the output from MATLAB Serial
        % Read
        ReadEditText
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    methods
        
        % Constructor implementation
        function obj = TestConnection(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.VerifyHardwareSetup(varargin{:});
            obj.Title.Text = message('px4:hwsetup:TestConn_Title').getString;
            
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Text = message('px4:hwsetup:Screen_Loading').getString;
            obj.BusySpinner.Visible = 'on';
            obj.BusySpinner.show();
            
            obj.ScreenDescription = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenDescription.Position = [20 280 400 100];
            obj.SelectionDropDown = matlab.hwmgr.internal.hwsetup.DropDown.getInstance(obj.ContentPanel);
            obj.SelectionLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            
            % Set EditTextCOMPort Properties
            obj.EditTextCOMPort = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.EditTextCOMPort.Position = [200 220 150 20];
            obj.EditTextCOMPort.TextAlignment = 'left';
            obj.EditTextCOMPort.Text = '<Enter Serial Port>';
            obj.EditTextCOMPort.Visible = 'off';
            
            % Set GetDataButton Properties
            obj.GetDataButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.GetDataButton.Text = message('px4:hwsetup:GetDataButton').getString;
            obj.GetDataButton.Position = [200 180 150 20];
            obj.GetDataButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.GetDataButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.GetDataButton.Visible = 'on';
            obj.GetDataButton.Enable = 'off';
            % Set callback when finish button is pushed
            obj.GetDataButton.ButtonPushedFcn = @obj.GetDataButtonCallback;
            
            % Set EditText Properties
            obj.ReadEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.ReadEditText.Position = [20 145 435 20];
            obj.ReadEditText.TextAlignment = 'left';
            obj.ReadEditText.Text = 'Accelerometer data (x,y,z) in m/s^2: 0.0 | 0.0 | 0.0';
            obj.ReadEditText.Visible = 'off';
            obj.ReadEditText.Enable = 'off';
            
            % Set Status Table Properties
            obj.StatusTable.Visible = 'off';
            obj.StatusTable.Enable = 'off';
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {''};
            obj.StatusTable.ColumnWidth = [20 350];
            obj.StatusTable.Position = [20 60 440 70];
            
            % Set the Label text
            obj.SelectionLabel.Text = message('px4:hwsetup:SelectCOMPortLabelWin').getString;
            obj.SelectionLabel.Position = [20 250 180 20];
            obj.SelectionLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            
            %Set callback function
            obj.SelectionDropDown.ValueChangedFcn = @obj.UpdateComPort;
            % Set SelectionDropDown Properties
            obj.SelectionDropDown.Position = [200 250 150 20];
            
            obj.SetSelectionDropDown();
            
            if ispc
                % Set HelpText Properties
                obj.HelpText.WhatToConsider = message('px4:hwsetup:TestConn_What_to_consider','PC').getString;
            elseif isunix
                %Set Linux Specific properties
                % Set HelpText Properties
                obj.HelpText.WhatToConsider = message('px4:hwsetup:TestConn_What_to_consider','computer').getString;
            end
            
            % Set DeviceInfo Table Properties
            obj.DeviceInfoTable.Visible = 'off';
            
            % Set Test Connection Button Properties
            obj.TestConnButton.Visible = 'on';
            obj.TestConnButton.Text = message('px4:hwsetup:TestConn_Button').getString;
            % Set callback when finish button is pushed
            obj.TestConnButton.ButtonPushedFcn = @obj.uploadFirmware;
            obj.TestConnButton.Position = [20 180 150 20];
            
            %Set the 'Test Connection' enable property
            obj.setScreenProperty();
            
            % Set HelpText Properties
            obj.HelpText.AboutSelection = '';
            
            obj.BusySpinner.Visible = 'off';
        end
        
        function setScreenProperty(obj)
            %To verify if the Build Firmware and Test Connection is
            %happening on the same folder. Workflow.Px4_Base_Dir can be
            %changed by going back to the Validate Screen and validating
            %a different folder while the build is in progress.
            
            % U1 = obj.Workflow.BuildExecuted
            % U2 = obj.Workflow.FirmwareUploaded
            % Y1 = obj.TestConnButton.Enable,obj.SelectionDropDown.Enable,obj.EditTextCOMPort.Enable
            % Y2 = obj.GetDataButton.Enable
            %-- U1 -- | -- U2 -- | -- Y1-- | -- Y2 --
            %   0     |    0     |   off   |    off
            %   0     |    1     |   off   |    off  (This condition is not possible)
            %   1     |    0     |   on    |    off
            %   1     |    1     |   off   |    on
            
            if strcmp(obj.Workflow.BuildExecuted,[obj.Workflow.Px4_Base_Dir,'_True']) && ~(obj.Workflow.FirmwareUploaded)
                obj.ScreenDescription.Text = message('px4:hwsetup:TestConn_Description',...
                    message('px4:hwsetup:TestConn_Button').getString,...
                    message('px4:hwsetup:GetDataButton').getString).getString;
                obj.TestConnButton.Enable = 'on';
                obj.SelectionDropDown.Enable = 'on';
                obj.EditTextCOMPort.Enable = 'on';
                obj.GetDataButton.Enable = 'off';
                
            elseif strcmp(obj.Workflow.BuildExecuted,[obj.Workflow.Px4_Base_Dir,'_True']) && (obj.Workflow.FirmwareUploaded)
                obj.ScreenDescription.Text = message('px4:hwsetup:TestConn_Description',...
                    message('px4:hwsetup:TestConn_Button').getString,...
                    message('px4:hwsetup:GetDataButton').getString).getString;
                obj.TestConnButton.Enable = 'off';
                obj.SelectionDropDown.Enable = 'off';
                obj.EditTextCOMPort.Enable = 'off';
                obj.GetDataButton.Enable = 'on';
                %Need not Warn the user if Multiple boards of same type are
                %connected to the Host Computer. As the Firmware is already
                %uploaded
                if any(find(strcmp(obj.StatusTable.Steps,message('px4:hwsetup:MultipleBoardsDetected',...
                        obj.Workflow.BoardName).getString)))
                    obj.StatusTable.Visible = 'off';
                end
            else
                obj.ScreenDescription.Text = message('px4:hwsetup:TestConn_FW_NotBuilt').getString;
                obj.TestConnButton.Enable = 'off';
                obj.SelectionDropDown.Enable = 'off';
                obj.EditTextCOMPort.Enable = 'off';
                obj.GetDataButton.Enable = 'off';
                %Need not Warn the user if Multiple boards of same type are
                %connected to the Host Computer. As the Firmware is already
                %uploaded
                if any(find(strcmp(obj.StatusTable.Steps,message('px4:hwsetup:MultipleBoardsDetected',...
                        obj.Workflow.BoardName).getString)))
                    obj.StatusTable.Visible = 'off';
                end
            end
        end
        
        function reinit(obj)
            
            %enableScreen enables all the widgets in the screen. make sure
            %to disable the ones you need.
            obj.enableScreen();
            
            obj.ReadEditText.Enable = 'off';
            obj.ReadEditText.Visible = 'off';
            
            obj.StatusTable.Visible = 'off';
            obj.BusySpinner.Visible = 'off';
            
            obj.SetSelectionDropDown();
            obj.setScreenProperty();
            
            drawnow;
        end
        
        function uploadFirmware(obj, ~, ~)
            % uploadFirmware - Callback when TestConnButton button (Upload Firmware) is pushed
            
            obj.ReadEditText.Visible = 'off';
            
            %verify the COM Port if the manual option is selected by the
            %user
            if (strcmp(obj.SelectionDropDown.Value,message('px4:hwsetup:SpecifyCOMPort').getString))
                [validCOMPort,reason] = obj.isValidCOMPort(obj.EditTextCOMPort.Text);
                if(~validCOMPort)
                    %Turn on the Status Table in case of Wrong Serial Port
                    obj.StatusTable.Visible = 'on';
                    obj.StatusTable.Enable = 'on';
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                    switch reason
                        case 'EmptyCOMPort'
                            obj.StatusTable.Steps = {message('px4:hwsetup:SerialPortEmpty').getString};
                        case 'COMPortUnavailable'
                            obj.StatusTable.Steps = {message('px4:hwsetup:COMPortNotFound', obj.EditTextCOMPort.Text).getString};
                    end
                    %Do not go further if the COM Port is not valid
                    return;
                else
                    %Update the COMPort with Edit Text value if Valid
                    obj.COMPort = obj.EditTextCOMPort.Text;
                end
            else
                %Update the COMPort if drop down is Valid
                obj.COMPort = obj.SelectionDropDown.Value;
            end
            
            uiwait(msgbox(message('px4:general:MsgBoxDescription').getString, message('px4:general:MsgBoxTitle').getString,'modal'));
            
            %Enable the Status table to show the status of Download and
            %customization
            message_arg = 'upload';
            obj.EnableStatusTable(message_arg);
            %Disable the testConnection and other Push Buttons when the upload is in
            %progress
            
            obj.disableScreen({'StatusTable','HelpText'});
            % Call the PX4FirmwareUpload function.
            UploadSuccess = true;
            try
                obj.Workflow.HardwareInterface.PX4FirmwareUpload(obj.Workflow,obj.COMPort);
            catch ME
                UploadSuccess = false;
                Exception = ME.message;
            end
            %Enable the Back, Next and Cancel buttons after the Upload is
            %done, irrespective of the result, as this is a Non Blocking Screen.
            obj.enableScreen();
            if UploadSuccess
                obj.StatusTable.Steps = {message('px4:hwsetup:TestConn_Pass',...
                    message('px4:hwsetup:GetDataButton').getString).getString};
                obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                
                %Set the FirmwareUploaded flag to true, as the latest
                %Firmware built is uploaded
                obj.Workflow.FirmwareUploaded = true;
                
            else
                obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                obj.StatusTable.Steps = {message('px4:hwsetup:TestConn_Fail',Exception).getString};
                %Set the FirmwareUploaded flag to false, as the latest
                %Firmware built is not uploaded
                obj.Workflow.FirmwareUploaded = false;
            end
            obj.setScreenProperty();
            
        end
        
        function GetDataButtonCallback(obj,~,~)
            message_arg = 'serialread';
            obj.EnableStatusTable(message_arg);
            obj.disableScreen({'StatusTable','HelpText'});
            try
                DisplayText = [];
                if strcmp(obj.Workflow.BoardName, message('px4:hwinfo:Crazyflie2_0').getString) || ...
					strcmp(obj.Workflow.BoardName, message('px4:hwinfo:CustomBoard').getString)
					DisplayText = obj.getMLSerialReadData(); % IO not supported for Crazyflie
                else
                    DisplayText = obj.getMLSerialReadDataIO(); % Read data using IO APIs
                end
            catch ME
                obj.ReadEditText.Visible = 'off';
                if contains(ME.identifier,'opfailed')
                    obj.EnableStatusTable('fopenfail');
                elseif (isunix) &&...
                        contains(ME.identifier,'readFailed')
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConn_SerialLinuxWarn',...
                        obj.Workflow.BoardName,obj.COMPort).getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Warn};
                else
                    obj.StatusTable.Steps = {ME.message};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                end
            end
            
            obj.enableScreen();
            obj.ReadEditText.Enable = 'off';
            if ~isempty(DisplayText)
                obj.ReadEditText.Text = DisplayText;
                obj.ReadEditText.Visible = 'on';
                obj.StatusTable.Steps = {message('px4:hwsetup:TestConn_GetDataPass',...
                    message('px4:hwsetup:GetDataButton').getString).getString};
                obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
            end
            obj.setScreenProperty();
        end
        
        function id = getPreviousScreenID(obj)
            id = obj.Workflow.HardwareInterface.getPreviousScreenTestConnection(obj.Workflow);
        end
        
        function out = getNextScreenID(~)
            out = 'codertarget.pixhawk.hwsetup.SetupComplete';
        end
    end
    
    methods(Access = private)
        
        function SetSelectionDropDown(obj)
            % Set the Drop down Items with available COM Ports
            usbDevices = matlab.hwmgr.internal.hwconnection.USBDeviceEnumerator;
            serialPortCellArray = usbDevices.getSerialPorts;
            %The last item in the drop down list is to manually specify the
            %COM Port option
            serialPortCellArray{end+1} = message('px4:hwsetup:SpecifyCOMPort').getString;
            obj.SelectionDropDown.Items = serialPortCellArray;
            
            %Keep a good default based on the board the user has selected.
            try
                COMPortFound = px4.internal.util.CommonUtility.getCOMPort(obj.Workflow.BoardName);
                COMPortFound = px4.internal.util.CommonUtility.verifyCOMPort(COMPortFound,obj.Workflow.BoardName);
                [~,indexFound] = find(strcmp(serialPortCellArray,COMPortFound));
            catch ME
                if strcmp(ME.identifier,'px4:hwsetup:TestConn_BoardNotFound')
                    indexFound = [];
                elseif strcmp(ME.identifier,'px4:general:MultipleBoardsDetected')
                    obj.EnableStatusTable('MultipleBoards');
                    return;
                end
            end
            
            if isempty(obj.COMPort)
                %First time the TestConnection screen is entered
                if isempty(indexFound)
                    %If Board is not detected
                    %Call the UpdateCOMPort function once to set the visibility of EditTextCOMPort
                    obj.UpdateComPort();
                else
                    %If board is detected, then set that as the default.
                    obj.SelectionDropDown.ValueIndex = indexFound;
                    obj.COMPort = COMPortFound;
                end
            else
                if ~isempty(indexFound)
                    %If board is detected, then set that as the default.
                    obj.SelectionDropDown.ValueIndex = indexFound;
                    obj.COMPort = COMPortFound;
                else
                    %This is to ensure that the COM Port selected is retained
                    %when the user goes back and forth to this screen
                    index = find(strcmp(serialPortCellArray,obj.COMPort));
                    if isempty(index)
                        %This could be when the COM Port is manually specified
                        if strcmpi(obj.COMPort,obj.EditTextCOMPort.Text)
                            %If the COM Port matches the COM Port specified via
                            %manual selection option, then set the drop down
                            %value to 'Specify Serial Port'
                            obj.SelectionDropDown.ValueIndex = length(serialPortCellArray);
                        else
                            %If board has been unplugged between the screens
                            if isequal(length(serialPortCellArray),1)
                                %Specify COMPort option is chosen automatically
                                obj.EditTextCOMPort.Visible = 'on';
                            else
                                obj.EditTextCOMPort.Visible = 'off';
                            end
                        end
                    else
                        obj.SelectionDropDown.ValueIndex = index;
                    end
                end
            end
            
        end%End of SetSelectionDropDown
        
        function UpdateComPort(obj, ~, ~)
            %Call back function when the selection item in the COM Port
            %drop down menu is changed
            if(strcmp(obj.SelectionDropDown.Value,message('px4:hwsetup:SpecifyCOMPort').getString))
                %When Specify COMPort option is chosen
                obj.EditTextCOMPort.Visible = 'on';
            else
                obj.EditTextCOMPort.Visible = 'off';
                obj.COMPort = obj.SelectionDropDown.Value;
            end
        end
        
        function EnableStatusTable(obj,message_arg)
            % Show all these widgets
            obj.StatusTable.Visible = 'on';
            obj.StatusTable.Enable = 'on';
            switch message_arg
                case 'upload'
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConn_Busy').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Busy};
                case 'serialread'
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConn_Busy_read').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Busy};
                case 'fopenfail'
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConn_FopenFail',...
                        obj.COMPort,message('px4:hwsetup:GetDataButton').getString).getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                case 'dataCorrupt'
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConn_dataCorrupt',...
                        message('px4:hwsetup:GetDataButton').getString).getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Warn};
                case 'dataEmpty'
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConn_dataEmpty',...
                        message('px4:hwsetup:GetDataButton').getString).getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                case 'MultipleBoards'
                    obj.StatusTable.Steps = {message('px4:hwsetup:MultipleBoardsDetected',...
                        obj.Workflow.BoardName).getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Warn};
                otherwise
                    obj.StatusTable.Steps = {message('px4:hwsetup:TestConn_Busy').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Busy};
            end
            
        end
        
        function data = getMLSerialReadData(obj)
            data = [];
            fread_data = obj.getFreadData();
            if ~isempty(fread_data)
                [packetFound,packet] = obj.getPacketData(fread_data);
                if packetFound
                    accData = obj.getAccelData(packet);
                    data = message('px4:hwsetup:TestConn_AccelData',...
                        num2str(accData(1)),num2str(accData(2)),num2str(accData(3))).getString;
                else
                    px4.internal.util.CommonUtility.localizedError('px4:hwsetup:TestConn_dataCorrupt',...
                        message('px4:hwsetup:GetDataButton').getString);
                    %                     obj.EnableStatusTable('dataCorrupt');
                    %Do Nothing. Implement retries if required
                end
            else
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:TestConn_dataEmpty',...
                    message('px4:hwsetup:GetDataButton').getString);
            end
        end%End of getMLSerialReadData function
        
        function data = getMLSerialReadDataIO(obj) %read accel values from hardware using Connected I/O APIs over serial
            data = [];
            % create serial transport layer
            transportObj = matlabshared.ioclient.transport.TransportLayerUtility.getTransportLayer( ...
                            'serial',obj.COMPort, 'Baudrate','115200');
            % create IO protocol obj
            IOProtocolObj = matlabshared.ioclient.IOProtocol(transportObj,'Checksum','enable');            
            isConnectSuccess = IOProtocolObj.connect();
            if isConnectSuccess
                %read accelerometer data
                try
                    accData = obj.getAccelDataIO(IOProtocolObj);
                catch
                    px4.internal.util.CommonUtility.localizedError('px4:hwsetup:TestConn_dataEmpty',...
                    message('px4:hwsetup:GetDataButton').getString);
                end
                if ~isempty(accData)
                    data = message('px4:hwsetup:TestConn_AccelData',...
                        num2str(accData(1)),num2str(accData(2)),num2str(accData(3))).getString;
                else
                    px4.internal.util.CommonUtility.localizedError('px4:hwsetup:TestConn_dataCorrupt',...
                        message('px4:hwsetup:GetDataButton').getString);
                    %                     obj.EnableStatusTable('dataCorrupt');
                    %Do Nothing. Implement retries if required
                end
            else
                px4.internal.util.CommonUtility.localizedError('px4:hwsetup:TestConn_dataEmpty',...
                    message('px4:hwsetup:GetDataButton').getString);
            end
        end%End of getMLSerialReadDataIO function
        
        function fread_data = getFreadData(obj)
            fread_data = [];
            %Sean's Serial doesn't need the below delete code
            %             delete(instrfind('Port',obj.COMPort));
            %                 s = serial(obj.COMPort);
            %Using Sean's serial as it is more robust in Linux
            s = matlabshared.seriallib.internal.Serial(obj.COMPort);
            s.BaudRate = 115200;
            %                 fopen(s);
            %Using Sean's serial as it is more robust in Linux
            connect(s);
            pause(1);
            
            %Data to Send
            % header = [7 7] and data = [9 9 9]; This will be read by the
            % Simulink model running on the target and respond
            % appropriately.
            dts = uint8([7 7 9 9 9 7 7 9 9 9]);
            
            %The px4_simulink_app verifies the command, and sends the accel data which
            %is being read
            %The px4_simulink_app sends 14 bytes (12(data) + 2(header)) * 10.
            expectedTotalPacketLen = 140;
            
            
            %------------- algo for simulink model sending only once---
            %             count = 0;
            %             i = 0;
            %             while (count ~= expectedTotalPacketLen || i > 10)
            %                 %Send command to px4_simulink_app to say that host is ready to receive.
            %                 %This will be implemented as callback of Test connection button
            %                 fwrite(s,dts);
            %                 pause(1);
            %                 [fread_data, count] = fread(s,expectedTotalPacketLen);
            %                 i = i + 1;
            %             end
            %------------- algo for simulink model sending only once---
            
            
            retry = 0;
            while isempty(fread_data) && retry < 2
                %Send command to px4_simulink_app to say that host is ready to receive.
                %                 fwrite(s,dts);
                %Using Sean's serial as it is more robust in Linux
                write(s,dts);
                pause(1);
                %Read the accelerometer data sent by the pixhawk board.
                %                 fread_data = fread(s,expectedTotalPacketLen);
                %Using Sean's serial as it is more robust in Linux
                fread_data = read(s,expectedTotalPacketLen);
                retry = retry + 1;
            end
            
            %close the connection after reading
            %             fclose(s);
            %Using Sean's serial as it is more robust in Linux
            disconnect(s);
            delete(s);
            if iscolumn(fread_data)
                %Sean's serial returns row vector, whereas normal serial
                %returns column vector.
                fread_data = fread_data';
            end
        end%End of getFreadData function
        
    end
    
    methods(Static)
        
        function [packetFound,packet] = getPacketData(fread_data)
            % This is the header sent by the Simulink model running on the
            % target. Header is followed by accelerometer data.
            header = [5 5];
            packetFound = false;
            packet = [];
            %Find the starting indices of fread_data where the header pattern is
            %found
            header_index = strfind(fread_data,header);
            
            %------------- algo for simulink model sending only once---
            %             if ~isempty(header_index) && header_index==1
            %extracting the data by stripping the header
            %                 packet = fread_data(3:14);
            %                 packetFound = true;
            %             end
            %------------- algo for simulink model sending only once---
            %Accel data is 12 bytes (3 (x,y,z) * 4 (single) bytes)
            expectedDataLen = 12;
            
            diff = expectedDataLen + length(header);
            if ~isempty(header_index)
                for i = 1:length(header_index)
                    %Verify whether the data in between the header indices is of
                    %expected Length (i.e header length + data length)
                    if isequal(header_index(i+1)-header_index(i),diff)
                        %Extract the data by stripping the header
                        packet = fread_data(header_index(i)+length(header):header_index(i+1)-1);
                        if ~isequal(length(packet),expectedDataLen)
                            %This error condition does not occur. This is for
                            %internal purposes only.
                            error(message('px4:hwsetup:TestConn_Wrong_Datalen',...
                                message('px4:hwsetup:GetDataButton').getString).getString);
                        end
                        packetFound = true;
                        break;
                    else
                        continue
                    end
                end
            end
        end%End of getPacketData function
        
        function accData = getAccelData(packet)
            accx = typecast(uint8(packet(1:4)),'single');
            accy = typecast(uint8(packet(5:8)),'single');
            accz = typecast(uint8(packet(9:12)),'single');
            accData = [accx,accy,accz];
        end
        
        function accData = getAccelDataIO(IOProtocolObj)
            uORBIOHandle = px4.internal.ConnectedIO.uORBIO;
            uORBID = uint8(px4.internal.ConnectedIO.uORBMsgMap.('sensor_accel'));
            %load busStruct for the sensor_accel uORB message
            busStructureMATFile= fullfile(codertarget.pixhawk.internal.getSpPkgRootDir,'lib','Customize_Setup','px4_simulink_app_IO','bus_sensor_accel.mat');
            load(busStructureMATFile,'bus_sensor_accel');
            %initialize uORB Read
            [orbMetadataObj,eventStructObj] = uORBReadInitialize (uORBIOHandle, IOProtocolObj, uORBID);
            BlockingMode = false;
            BlockTimeout = 0.01;
            %read 'sensor_accel' uORB message
            [msg,~] = uORBReadMessage (uORBIOHandle,IOProtocolObj, orbMetadataObj, ...
                                        eventStructObj, BlockingMode, (BlockTimeout)*1000,bus_sensor_accel);
            %call release function                    
            uORBReadRelease (uORBIOHandle,IOProtocolObj,orbMetadataObj);
            delete(IOProtocolObj);
            accData = single([msg.x,msg.y,msg.z]);        
        end
        
        function [status,cmd] = isValidCOMPort(COMPort)
            %Function to validate the COM Port entered by the user
            if isempty(COMPort)
                status = false;
                cmd = 'EmptyCOMPort';
                return;
            else
                usbDevices = matlab.hwmgr.internal.hwconnection.USBDeviceEnumerator;
                COMPortAvailable = usbDevices.getSerialPorts() ;
                if ~ismember(COMPort, COMPortAvailable)
                    status = false;
                    cmd = 'COMPortUnavailable';
                    return;
                end
            end
            status = true;
            cmd=[];
        end%End of isValidCOMPort function
    end
    
end
