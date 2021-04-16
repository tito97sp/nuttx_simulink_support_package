function startDaemon(hObj)
%StartDaemon Starts the Java daemon to run in the background
%   comPort and portSpeed MUST be populated with the appropriate data
%   before calling the daemon

%   Copyright 2018-2020 The MathWorks, Inc.
% This is for PX4 targets

if ispc()
    javaName = 'java.exe';
    GREP_CMD = 'find';
    GREP = fullfile(getenv('windir'), 'system32', GREP_CMD);
    % we do this to force call find.exe from the system32 path
    % otherwise matlab supersedes this with a MKSTK find
else
    javaName = 'java';
    GREP_CMD = 'grep';
    GREP = fullfile(GREP_CMD);
end

javaPath    = fullfile(matlabroot, 'sys', 'java', 'jre', computer('arch'), 'jre', 'bin', javaName);
daemonRoot  = fullfile(matlabshared.externalmode_daemon.getDaemonRootDir, 'daemon');
rxtxPath    = fullfile(matlabroot, 'java', 'jarext');
cBuffPath   = fullfile(matlab.internal.get3pInstallLocation('ostermillercircularbuffer.instrset'), 'ostermillerutils-1.08.02');
rxtxlibPath = fullfile(matlabroot, 'bin',  computer('arch'));

javaPath    = RTW.TransformPaths(javaPath,    'pathType', 'alternate');
daemonRoot  = RTW.TransformPaths(daemonRoot,  'pathType', 'alternate');
rxtxPath    = RTW.TransformPaths(rxtxPath,    'pathType', 'alternate');
cBuffPath   = RTW.TransformPaths(cBuffPath,   'pathType', 'alternate');
rxtxlibPath = RTW.TransformPaths(rxtxlibPath, 'pathType', 'alternate');

comPort = codertarget.pixhawk.internal.getExternalSerialPortName(hObj);

portSpeed = num2str(codertarget.pixhawk.internal.getExternalModeBaudrate(hObj));


serialDelay = '0';
%Effect : Passed as an argument to the daemon, makes the daemon wait for 'delay' secs before receiving data on the COM port.
%Why    : Daemon opens the com port, but, does not collect any serial data for this duration.
%         Avoids the IP sent again by the PX4 on the reset caused by the port.open() in the daemon.

ethernetTimeout = '60';
%Effect : Passed as an argument to the daemon, makes the Ethernet server wait for 'timeout' seconds to accept connections
%Why    : We don't want the daemon to remain up (forever) if matlab launches it, but, does not connect to it due to an error
%NOTE   : Unusual behaviour - Setting timeout to '0' results in an infinite wait.

if ispc()
    args = [' -Djava.library.path="' rxtxlibPath '" -cp ".\;' rxtxPath '\RXTXcomm.jar;' cBuffPath '\ostermillerutils-1.08.02.jar;' daemonRoot '\daemon.jar"' ' daemon.SerialNetworkDaemon'];
elseif ismac()
    args = [' -Djava.library.path="' rxtxlibPath '" -cp "' rxtxPath '/RXTXcomm.jar":"' cBuffPath '/ostermillerutils-1.08.02.jar":"' daemonRoot '/daemon.jar"' ' daemon.SerialNetworkDaemon'];
elseif isunix()
    args = [' -Djava.library.path="' rxtxlibPath '"' ' -Dgnu.io.rxtx.SerialPorts="' comPort '" -cp "' rxtxPath '/RXTXcomm.jar":"' cBuffPath '/ostermillerutils-1.08.02.jar":"' daemonRoot '/daemon.jar"' ' daemon.SerialNetworkDaemon'];
end

args = [args ' ' comPort ' ' portSpeed ' ' serialDelay ' ' ethernetTimeout];

rtw.connectivity.Utils.launchProcess(javaPath, args);

%check if the daemon is up by verifying if someone is listening on 17725
stdout = '';
scanPortTimeout = 60;
tic;
while ( isempty(stdout) && toc < scanPortTimeout )
    [~, stdout] = system(['netstat -an | ' GREP ' ":17725"']);
    pause(1);
end

end
