function makeCmd = nuttx_ec_wrap_make_cmd_hook(args)
%MAKE_ARDUINO wrap_make_cmd hook

%   Copyright 2009-2014 The MathWorks, Inc.

if ispc
    makeCmd = args.makeCmd;
    arduino_path = arduino_ec.Prefs.getArduinoPath;
    args.make = strrep(args.make,'%ARDUINO_ROOT%',...
        arduino_path);
    args.makeCmd = strrep(makeCmd,'%ARDUINO_ROOT%',...
        arduino_path);

    makeCmd = setup_for_default(args);
else
    makeCmd = fullfile(matlabroot,'bin',lower(computer),'gmake');
    pcMakeCmd = '%ARDUINO_ROOT%/hardware/tools/avr/utils/bin/make';
    len=length(pcMakeCmd);
    assert(strncmp(args.makeCmd, pcMakeCmd, len), ...
        'makeCmd must default to PC Make command');
    makeCmd = [makeCmd args.makeCmd(len+1:end)];
end
