function setup_customtarget_nuttx
%%   Arduino setup
%   Copyright 2012-2014 The MathWorks, Inc. 
%

%% Add path for blocks and arduino target files
addpath(fullfile(pwd,'nuttx_ec'), fullfile(pwd,'blocks'))

result = savepath;
if result==1
    nl = char(10);
    msg = [' Unable to save updated MATLAB path (<a href="http://www.mathworks.com/support/solutions/en/data/1-9574H9/index.html?solution=1-9574H9">why?</a>)' nl ...
           ' Exit MATLAB, right-click on the MATLAB icon, select "Run as administrator", and re-run setup_customtarget_nuttx.m' nl ...
           ];
    error(msg);
else
    disp(' Saved updated MATLAB path');
    disp(' ');
end


%% Build S-functions 
%build_all_sfunctions

%% Register PIL/ExtMode communication interface
%sl_refresh_customizations

%% Set path for Arduino software. It's highly recommended version 1.0.5 or later
% Download from http://arduino.cc/en/Main/Software

%arduino_ec.Prefs.setArduinoPath('c:\Arduino-1.0.5')

% Set board version (uno, mega, mega2560, leonardo, ...
%arduino_ec.Prefs.setBoard('uno');  % Choose a specific board name
                                % List of valid names is under 
                                % c:\arduino-1.0.5\hardware\arduino\boards.txt 

% Set PIL/ExtMode communication speed
%arduino_ec.Prefs.setPILSpeed(115200);  % PIL/ExtMode serial port speed

% Search for Arduino COM port.
%comPorts=arduino_ec.Prefs.searchForComPort;
% if isempty(comPorts)       % No any Com found, take some to be possible to continue
%     comPorts={'COM5'};
%     fprintf('No any Arduino COM Port found, taking %s to bypass troubles.\n', comPorts{1});
% else
%     fprintf('Arduino "%s" detected on %s.\n', arduino_ec.Prefs.getBoard, comPorts{1});
% end
% 
% arduino_ec.Prefs.setComPort(comPorts{1});
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Newer avr-gcc compilers (4.7.2, 4.8.0 and 4.8.2)
%
%       Sourceforge (Version 4.8.0)
%       http://sourceforge.net/projects/mobilechessboar/files/avr-gcc%20snapshots%20(Win32)
%
%       Version 4.8.2 and older
%       https://infernoembedded.com/products/avr-tools
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
