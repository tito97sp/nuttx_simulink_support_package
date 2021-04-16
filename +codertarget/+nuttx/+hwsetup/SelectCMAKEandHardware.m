classdef SelectCMAKEandHardware < matlab.hwmgr.internal.hwsetup.SelectionWithDropDown
    % SelectCMAKEandHardware - Screen implementation to enable users to select the
    % PX4 Supported Hardware board and the corresponding CMAKE selection.
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % ImageFiles - Cell array of full paths to the image files. The
        % number of elements in ImageFiles should be equal to the number of
        % items in the pop-up menu (cell)
        ImageFiles = {};
        % HelpForSelection - Cell array strings/character-vectors for
        % providing more information about the selected item. This will be
        % rendered in the "About Your Selection" section in the HelpText
        % panel
        HelpForSelection = {};
        
        % Map object which contains the position of the image corresponding to the
        % board
        BoardPositionMap
        
        % SelectionDropDownCMAKE - Pop-up menu to display the list of items to choose
        % from (DropDown)
        SelectionDropDownCMAKE
        % SelectionLabelCMAKE - Text describing the category of the items in the
        % pop-up menu e.g. hardware, devices etc. (Label)
        SelectionLabelCMAKE
        % ValidateEditText - Text box area to show install location that has
        % to be validated.
        ValidateEditText
        % BrowseButton - Button that on press opens a filesystem browser
        % for user to pick the correct install location.
        BrowseButton
    end
    
    properties( Access = private, Hidden)
        % Spinner widget
        BusySpinner
    end
    
    methods
        function obj = SelectCMAKEandHardware(varargin)
            % call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.SelectionWithDropDown(varargin{:});
            
            % Set the Title Text
            obj.Title.Text = message('px4:hwsetup:SelectCMAKEHardware_Title').getString;
            %Default position is [20 7 470 25], But increasing it to accommodate the lengthier title
            obj.Title.Position = [20 7 550 25];
            
            % Set the Description text area
            obj.Description.Text = message('px4:hwsetup:SelectCMAKEHardwareBoard_Description').getString;
            
            obj.ValidateEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.BrowseButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            
            % Set ValidateEditText Properties
            obj.ValidateEditText.Position = [180 210 205 20];
            obj.ValidateEditText.TextAlignment = 'left';
            obj.ValidateEditText.Text =  message('px4:hwsetup:SelectCMAKE_EditText').getString;
            obj.ValidateEditText.Visible = 'off';
            obj.ValidateEditText.Enable = 'off';
            
            % Set BrowseButton Properties
            obj.BrowseButton.Text = message('px4:hwsetup:BrowseButtonText').getString;
            obj.BrowseButton.Position = [380 210 70 20];
            obj.BrowseButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.HELPBLUE;
            obj.BrowseButton.Visible = 'off';
            % Set callback when Browse button is pushed
            obj.BrowseButton.ButtonPushedFcn = @obj.browseDirectory;
            
            obj.SelectionDropDownCMAKE = matlab.hwmgr.internal.hwsetup.DropDown.getInstance(obj.ContentPanel);
            obj.SelectionLabelCMAKE = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            
            % Set the Label text
            obj.SelectionLabel.Text = message('px4:hwsetup:SelectBoardLabel').getString;
            obj.SelectionLabelCMAKE.Text = [message('px4:hwsetup:SelectCMAKE_Title').getString,':'];
            
            % Set the Drop down Items for boards
            obj.SelectionDropDown.Items = obj.Workflow.Boards;
            % Select the first entry in DropDown - Pixhawk 1
            obj.SelectionDropDown.ValueIndex = 1;
            obj.Workflow.BoardName = obj.SelectionDropDown.Value;
            
            %Set the drop down items for cmake selection
            %Get the cmake config file corresponding to the Hardware board
            %selected.
            configs = obj.Workflow.BoardConfigMap(obj.Workflow.BoardName);
            
            %Set callbacks for dropdown menus
            obj.SelectionDropDown.ValueChangedFcn = @obj.BoardChangeCallback;
            obj.SelectionDropDownCMAKE.ValueChangedFcn = @obj.CMAKEchangeCallback;
            obj.SelectionDropDownCMAKE.Visible = 'on';
            obj.SelectionDropDownCMAKE.Items = configs;
            %Add the option to choose custom config at the end of the list
            % Select the first entry in DropDown -
            % px4_sitl_default.cmake
            obj.SelectionDropDownCMAKE.ValueIndex = 1;
            
            % Set the What To Consider section of the HelpText
            obj.HelpText.WhatToConsider = '';
            
            imgDir = obj.Workflow.HardwareInterface.getImageDir(obj.Workflow,'screens');
            % Set the default Image to be displayed for PX4 Host Target
            obj.SelectedImage.ImageFile = '';
            % Set the default About Selection HelpText for PX4 Host Target
            obj.HelpText.AboutSelection = message('px4:hwsetup:PX4HostTarget_Info').getString;
            
            % Set the HelpForSelection property to update the HelpText
            % when the Item in the DropDown changes
            obj.HelpForSelection = { message('px4:hwsetup:PX4HostTarget_Info').getString,...
                message('px4:hwsetup:Pixhawk1_Info').getString,...
                message('px4:hwsetup:Pixhawk2_Info').getString,...
                message('px4:hwsetup:PixRacer_Info').getString,...
                message('px4:hwsetup:Pixhawk4_Info').getString,...
                message('px4:hwsetup:Crazyflie2_0_Info').getString,...
                '',...
                };
            
            % Set the ImageFiles property to update the SelectedImage
            % when the Item in the DropDown changes
            obj.ImageFiles = {...
                '',...
                fullfile(imgDir, 'pixhawk1.png'),...
                fullfile(imgDir, 'pixhawk2.2.png'),...
                fullfile(imgDir, 'pixracer.png'),...
                fullfile(imgDir, 'pixhawk4.png'),...
                fullfile(imgDir, 'crazyflie2_0.png'),...
                '',...
                };
            
            %Position data is arrived by getting pixel info for each of the
            %boards. (eg- imread(pixhawk1.png))
            %TODO - This step of getting the position can be automated
            position = {[200 5 127 200],... //Dummy position for PX4 Host Target to make the number of keys and values same
                [200 5 125 200],...
                [200 5 102 200],...
                [200 5 211 200],...
                [200 5 127 200],...
                [150 5 177 200],...
                [200 5 127 200],... //Dummy position to make the number of keys and values same
                };
            
            obj.BoardPositionMap = containers.Map(obj.Workflow.Boards,position,'UniformValues',false);
            
            obj.AlignWidgetPosition();
            %Position data for default board : PX4 Host Target
            obj.SelectedImage.Position = [200 5 127 200];
            
        end
        
        function reinit(obj)
            %Disable the BusySpinner after screen loads
            obj.BusySpinner.Visible = 'off';
            %Below is for debugging only.
            %             obj.AlignWidgetPosition();
        end
        
        function AlignWidgetPosition(obj)
            % Align the widgets
            
            obj.SelectionLabel.Position = [20 290 180 20];
            obj.SelectionDropDown.Position = [200 290 230 20];
            p2 = obj.Description.Position;
            obj.Description.Position = [p2(1) 320 p2(3) 60];
            obj.SelectionLabelCMAKE.Position = [20 250 180 20];
            obj.SelectionDropDownCMAKE.Position = [200 250 230 20];
        end
        
        function set.ImageFiles(obj, files)
            % ImageFiles property should be specified as a cell array of
            % strings or character vectors
            assert((iscellstr(files) || isstring(files)), 'ImageFiles property should be specified as a cell array of strings or character vectors');
            obj.ImageFiles = files;
        end
        
        function set.HelpForSelection(obj, helptext)
            % HelpForSelection property should be specified as a cell array of
            % strings or character vectors
            assert((iscellstr(helptext) || isstring(helptext)), 'HelpForSelection property should be specified as a cell array of strings or character vectors');
            obj.HelpForSelection = helptext;
        end
        
        function BoardChangeCallback(obj,~,~)
            % BoardChangeCallback - Callback for the Board selection DropDown
            
            if strcmp(obj.SelectionDropDown.Value,message('px4:hwinfo:CustomBoard').getString)
                %Setting isCustomConfig as true, to have the edit box
                %enabled in Build screen
                obj.Workflow.isCustomConfig = true;
            else
                obj.Workflow.isCustomConfig = false;
            end
            % Save the selected Board to the Workflow class
            obj.Workflow.BoardName = obj.SelectionDropDown.Value;
            
            %Change image and HelpText based on board selected
            obj.changeImageandHelp();
            
            %Change drop down options of cmake based on board selected
            obj.changeCMAKEDropDownList();
            
        end%End of BoardChangeCallback
        
        function CMAKEchangeCallback(obj,~,~)
            if strcmp(obj.SelectionDropDownCMAKE.Value,message('px4:hwsetup:SelectCMAKE_CustConfig').getString)
                
                %Setting isCustomConfig as true, to have the edit box
                %enabled in Build screen
                obj.Workflow.isCustomConfig = true;
                
                %If custom CMAKE option is selected, then display Edit box
                %and Browse buttons
                obj.setDisplayPropertyBrowseEdit('on','down');
                
                %Check if the custom cmake is selected, and accordingly
                %enable/disable Next button
                obj.setNextButtonEnableProperty();
            else
                obj.Workflow.isCustomConfig = false;
                obj.NextButton.Enable = 'on';
                obj.setDisplayPropertyBrowseEdit('off');
            end
        end
        
        function browseDirectory(obj, ~, ~)
            % browseDirectory - Callback when browse button is pushed that launches the
            % file browsing window set to the directory indicated by obj.ValidateEditText.Text
            
            Px4_Cmake_Config_Path = fullfile(obj.Workflow.Px4_Base_Dir,...
                'Firmware','boards');
            [file,path] = uigetfile([Px4_Cmake_Config_Path filesep '*.cmake']);
            
            if isfile(fullfile(path,file)) % If the user cancels the file browser, uigetfile returns 0.
                obj.NextButton.Enable = 'on';
                % When a new location is selected, then set that location value
                % back to show it in edit text area. (ValidateEditText.Text).
                folderNames = strsplit(strip(path,filesep), filesep);
                if numel(folderNames) <2
                    px4.internal.util.CommonUtility.localizedError('px4:hwsetup:DownValPX4_cmakeFile_InvalidCustomCmake',file);
                end
                obj.ValidateEditText.Text = strcat(folderNames{end-1}, '_',folderNames{end}, '_', erase(file, '.cmake'));
            else
                obj.NextButton.Enable = 'off';
            end
        end
        
        function PreviousScreen = getPreviousScreenID(~)
            PreviousScreen = 'codertarget.pixhawk.hwsetup.SelectAlgorithm';
        end
        
        function out = getNextScreenID(obj)
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            %Set the Busy Spinner text
            obj.BusySpinner.Text = message('px4:hwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();
            
            if(obj.Workflow.isCustomConfig)
                %Get the custom cmake selected
                file = obj.ValidateEditText.Text;
                
                obj.Workflow.HardwareInterface.validateCMake(obj.Workflow, file);
                obj.Workflow.HardwareInterface.customizePX4Firmware(obj.Workflow);
                %Add the 'modules/px4_simulink_app' to the custom
                %CMAKE file that the user chooses
                obj.Workflow.HardwareInterface.modifyCmakeFile(...
                    obj.Workflow,file);
            elseif ~strcmp(obj.SelectionDropDownCMAKE.Value,message('px4:hwsetup:SelectCMAKE_CustConfig').getString)...
                    && ~strcmp(obj.Workflow.BoardName,message('px4:hwinfo:CustomBoard').getString)
                
                obj.Workflow.HardwareInterface.validateCMake(obj.Workflow, obj.SelectionDropDownCMAKE.Value);
                %Add the 'px4_simulink_app' to the
                %CMAKE file that the user chooses
                obj.Workflow.HardwareInterface.modifyCmakeFile(...
                    obj.Workflow, obj.Workflow.Px4_Cmake_Config);
                if strcmp(obj.Workflow.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                    try
                        %copy files to px4_simulink_app for building Connected I/O Firmware
                        obj.Workflow.HardwareInterface.customizePX4IOFirmwareForSITL(obj.Workflow);
                        px4Setup = obj.Workflow.HardwareInterface.getPX4FirmwareSetUpObj(obj.Workflow);
                        px4Setup.modifyStartupScriptIfNeeded();
                    catch ME
                        obj.BusySpinner.Visible = 'off';
                        throw(ME);
                    end
                elseif strcmp(obj.Workflow.BoardName, message('px4:hwinfo:Crazyflie2_0').getString)
                    obj.Workflow.HardwareInterface.customizePX4Firmware(obj.Workflow);
                    obj.Workflow.HardwareInterface.modifyStartupScript(...
                        obj.Workflow, '');
                else
                    obj.Workflow.HardwareInterface.customizePX4Firmware(obj.Workflow);
                    px4Setup = obj.Workflow.HardwareInterface.getPX4FirmwareSetUpObj(obj.Workflow);
                    px4Setup.handleControllerModules('retain');
                end
                
            end
            out = obj.Workflow.HardwareInterface.getNextScreenSelectCMAKE(obj.Workflow);
        end
    end
    
    methods (Access = private)
        
        function changeCMAKEDropDownList(obj)
            if strcmp(obj.Workflow.BoardName,message('px4:hwinfo:CustomBoard').getString)
                %When Custom Board option is selected in Select Hardware
                %Screen, only Custom CMAKE file option is given
                
                %Check if the custom cmake is selected, and accordingly
                %enable/disable Next button
                obj.setNextButtonEnableProperty();
                
                %Turn off drop down for CMAKE selection
                obj.SelectionDropDownCMAKE.Visible = 'off';
                
                obj.setDisplayPropertyBrowseEdit('on','up');
                
            else
                %Get the cmake config file corresponding to the Hardware board
                %selected.
                configs = obj.Workflow.BoardConfigMap(obj.Workflow.BoardName);
                obj.setDisplayPropertyBrowseEdit('off');
                obj.SelectionDropDownCMAKE.Visible = 'on';
                obj.SelectionDropDownCMAKE.Items = configs;
                if ~strcmp(obj.Workflow.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                    obj.SelectionDropDownCMAKE.Items{end+1} =  message('px4:hwsetup:SelectCMAKE_CustConfig').getString;
                end
                % Select the first entry in DropDown
                obj.SelectionDropDownCMAKE.ValueIndex = 1;
            end
        end%End of changeCMAKEDropDownList
        
        function changeImageandHelp(obj)
            % CHANGEIMAGE - Callback for the DropDown that changes the
            % image file based on the index of the selected item in the
            % drop down
            
            if strcmpi(obj.SelectionDropDown.Value,message('px4:hwinfo:CustomBoard').getString)
                obj.HelpText.WhatToConsider = message('px4:hwsetup:CustomBoard_WhatToConsider').getString;
            elseif strcmp(obj.Workflow.BoardName, message('px4:hwinfo:PX4HostTarget').getString)
                obj.HelpText.WhatToConsider = '';
            else
                obj.HelpText.WhatToConsider = obj.Workflow.HardwareInterface.getSelectHardwarePX4HelpText();
            end
            
            if ~isempty(obj.ImageFiles)
                if obj.SelectionDropDown.ValueIndex <= numel(obj.ImageFiles)
                    % If the ImageFiles array has been specified and the items
                    % in the array are greater than or equal to the index of
                    % the selected item, assign the SelectedImage property
                    obj.SelectedImage.ImageFile = ...
                        obj.ImageFiles{obj.SelectionDropDown.ValueIndex};
                    obj.SelectedImage.Position = obj.BoardPositionMap(obj.Workflow.BoardName);
                else
                    obj.SelectedImage.ImageFile = '';
                end
            end
            
            if ~isempty(obj.HelpForSelection)
                if  obj.SelectionDropDown.ValueIndex <= numel(obj.HelpForSelection)
                    % If the HelpForSelection has been specified and the items
                    % in the array are greater than or equal to the index of
                    % the selected item, assign the HelpText property
                    obj.HelpText.AboutSelection = ...
                        obj.HelpForSelection{obj.SelectionDropDown.ValueIndex};
                else
                    obj.HelpText.AboutSelection = '';
                end
            end
        end
        
        function setNextButtonEnableProperty(obj)
            %Check if the custom cmake is selected, and accordingly
            %enable/disable Next button
            if contains(obj.ValidateEditText.Text,message('px4:hwsetup:SelectCMAKE_EditText').getString,'IgnoreCase',true)
                obj.NextButton.Enable = 'off';
            else
                obj.NextButton.Enable = 'on';
            end
        end
        
        function setDisplayPropertyBrowseEdit(obj,flag,varargin)
            if strcmpi(flag,'on')
                switch lower(varargin{1})
                    case 'up'
                        obj.ValidateEditText.Position = [200 250 190 20];
                        obj.BrowseButton.Position = [400 250 65 20];
                        obj.BrowseButton.Visible = 'on';
                        obj.ValidateEditText.Visible = 'on';
                    case 'down'
                        obj.ValidateEditText.Position = [200 215 190 20];
                        obj.BrowseButton.Position = [400 215 65 20];
                        obj.BrowseButton.Visible = 'on';
                        obj.ValidateEditText.Visible = 'on';
                    otherwise
                        obj.ValidateEditText.Position = [200 215 190 20];
                        obj.BrowseButton.Position = [400 215 65 20];
                        obj.BrowseButton.Visible = 'on';
                        obj.ValidateEditText.Visible = 'on';
                end
            elseif strcmpi(flag,'off')
                obj.BrowseButton.Visible = 'off';
                obj.ValidateEditText.Visible = 'off';
            else
                obj.BrowseButton.Visible = 'off';
                obj.ValidateEditText.Visible = 'off';
            end
        end
    end
    
end
