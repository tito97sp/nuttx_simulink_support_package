function openViewAxisInfo(~)
% OPENVIEWAXISINFO
% This is a 'View Axis Info' callback function opens the NED Axis info image for
% Pixhawk Series boards

% Copyright 2019-2020 The MathWorks, Inc.
spkgrootDir = codertarget.pixhawk.internal.getSpPkgRootDir;
fName = 'NED.png';
imgFile = fullfile(spkgrootDir,'resources',fName);
imgTitle = 'Pixhawk Axis Information';
% Look for the figure window and bring forward.
imgHandle = findobj('type','figure','Name',imgTitle,'Tag','pixhawkOpenAxisInfo');
if (numel(imgHandle) == 1) && ishandle(imgHandle)
    %Figure window already opened. Bring it to front.
    figure(imgHandle);
    hax = axes( ...
        'Parent',imgHandle, ...
        'Visible','off');
    imshow(imgFile,'parent',hax,'border','tight');
else
    %Cannot find any opened figure. Create new
    if ~isempty(imgFile) && exist(imgFile,'file') == 2
        fig = figure( ...
            'Name', imgTitle, ...
            'NumberTitle', 'off',...
            'MenuBar','none','Tag','pixhawkOpenAxisInfo');
        hax = axes( ...
            'Parent',fig, ...
            'Visible','off');
        imshow(imgFile,'parent',hax,'border','tight');
    end
end
end
