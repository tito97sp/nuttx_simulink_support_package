function [tc, results] = gnu_gcc_nuttx_embedded()
%gnu_gcc_px4_embedded Toolchain definition file for PX4

% Copyright 2018-2019 The MathWorks, Inc.

toolchain.Platforms  = {computer('arch')};
toolchain.Versions   = {'7.2.1'};
toolchain.Artifacts  = {'gmake'};
toolchain.FuncHandle = str2func('getToolchainInfoFor');
toolchain.ExtraFuncArgs = {};

[tc, results] = coder.make.internal.generateToolchainInfoObjects(mfilename, toolchain);
end

function tc = getToolchainInfoFor(platform, version, artifact, varargin)
% Toolchain Information

tc = coder.make.ToolchainInfo('BuildArtifact', 'gmake makefile', 'SupportedLanguages', {'C/C++'});
tc.Name = coder.make.internal.formToolchainName('Tools for Nuttx targets', ...
    platform, version, artifact);
tc.Platform = platform;
tc.setBuilderApplication(platform);


% Toolchain's attribute
tc.addAttribute('TransformPathsWithSpaces');
tc.addAttribute('SupportsUNCPaths',     false);
tc.addAttribute('SupportsDoubleQuotes', true);
if isequal(platform,'win64')
    tc.addAttribute('RequiresBatchFile');
end


end
