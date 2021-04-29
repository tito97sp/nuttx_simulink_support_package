function nuttx_ec_select_callback_handler(hDlg, hSrc)
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
slConfigUISetVal(hDlg, hSrc, 'ProdHWDeviceType', 'ARM Compatible->ARM Cortex-M');
slConfigUISetVal(hDlg, hSrc, 'ProdLongLongMode', 'on');

% Set the TargetLibSuffix
slConfigUISetVal(hDlg, hSrc, 'TargetLibSuffix', '.a');

% Set the MakeFileGenerator disactivated
slConfigUISetVal(hDlg, hSrc, 'GenerateMakefile', 'off');
slConfigUISetEnabled(hDlg, hSrc, 'GenerateMakefile', false);

%$ Set the PostCodeGenCommand
slConfigUISetVal(hDlg, hSrc, 'PostCodeGenCommand', 'nuttx_ec.onAfterCodeGen(Simulink.ConfigSet, buildInfo)');

% For real-time builds, we must generate ert_main.c
slConfigUISetVal(hDlg, hSrc, 'ERTCustomFileTemplate', 'nuttx_ec_file_process.tlc');
slConfigUISetEnabled(hDlg, hSrc, 'ERTCustomFileTemplate', false);

slConfigUISetVal(hDlg, hSrc, 'GenerateSampleERTMain', 'off');
slConfigUISetEnabled(hDlg, hSrc, 'GenerateSampleERTMain', false);

% For real-time concurrent task builds.
slConfigUISetVal(hDlg, hSrc, 'ConcurrentExecutionCompliant', 'on');
slConfigUISetEnabled(hDlg,hSrc,'ConcurrentExecutionCompliant',false);

hSrc.refreshDialog;

end
