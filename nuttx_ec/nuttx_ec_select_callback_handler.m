function arduino_ec_select_callback_handler(hDlg, hSrc)
%NUTTX_EC_SELECT_CALLBACK_HANDLER callback handler for Nuttx target

%   Copyright 2009-2014 The MathWorks, Inc.

% The target is model reference compliant
slConfigUISetVal(hDlg, hSrc, 'ModelReferenceCompliant', 'on');
slConfigUISetEnabled(hDlg, hSrc, 'ModelReferenceCompliant', false);

% Hardware being used is the production hardware
slConfigUISetVal(hDlg, hSrc, 'ProdEqTarget', 'on');

% Setup C++ as default language
slConfigUISetVal(hDlg, hSrc, 'TargetLang', 'C++');

% Setup the hardware configuration
slConfigUISetVal(hDlg, hSrc, 'ProdHWDeviceType', 'STM32->Nucleo_H743ZI');

% Set the TargetLibSuffix
slConfigUISetVal(hDlg, hSrc, 'TargetLibSuffix', '.a');

% For real-time builds, we must generate ert_main.c
slConfigUISetVal(hDlg, hSrc, 'ERTCustomFileTemplate', 'nuttx_ec_file_process.tlc');

%slConfigUISetVal(hDlg, hSrc, 'ConcurrentExecutionCompliant', 'on');

end
