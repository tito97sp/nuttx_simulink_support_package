function sl_customization(cm)
% SL_CUSTOMIZATION for Arduino_EC PIL connectivity config

% Copyright 2008-2014 The MathWorks, Inc.

cm.registerTargetInfo(@loc_createSerialConfig);
cm.ExtModeTransports.add('nuttx_ec.tlc', 'tcpip',  'ext_comm', 'Level1');
cm.ExtModeTransports.add('nuttx_ec.tlc', 'serial', 'ext_serial_win32_comm', 'Level1');

% local function
function config = loc_createSerialConfig

config = rtw.connectivity.ConfigRegistry;
config.ConfigName = 'Nuttx connectivity config using serial';
config.ConfigClass = 'nuttx_ec.ConnectivityConfig';

% matching system target file
config.SystemTargetFile = {'nuttx_ec.tlc'};

% match template makefile
config.TemplateMakefile = {'nuttx_ec.tmf'};

% match any hardware implementation
config.TargetHWDeviceType = {};
