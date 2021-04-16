%   Copyright 2018-2019 The MathWorks, Inc.
classdef px4
    %   px4
    %   Useful to get the doc root of the support package.
 
    properties
    end
 
    methods(Static)
        function docRoot = getDocRoot()
            sppkgNameTag = hwconnectinstaller.SupportPackage.getPkgTag('px4');
            myLocation = mfilename('fullpath');
            docRoot = matlabshared.supportpkg.internal.getSppkgDocRoot(myLocation, sppkgNameTag);
            if isempty(docRoot)
                error(message('hwconnectinstaller:setup:HelpMissing'));
            end
        end
    end
 
end
