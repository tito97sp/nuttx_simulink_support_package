function postCodeGenHook(hCS, buildInfo)
%This function is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

    validateattributes(hCS, {'Simulink.ConfigSet'}, {'scalar'});
    validateattributes(buildInfo, {'RTW.BuildInfo'}, {'scalar'});

    model = buildInfo.ModelName;

    % Get the build directory (that's where we will put the generated files)
    buildDir = getSourcePaths(buildInfo, true, {'BuildDir'});
    if isempty(buildDir)
        buildDir = pwd;
    else
        buildDir = buildDir{1};
    end

    if nuttx.internal.cgen.Util.isTopLevelModel(buildInfo)
        modelinfo = nuttx.internal.cgen.NuttxModelInfo(model);
        topicTypes = modelinfo.topicTypesInModel();
        conversionFiles = nuttx.internal.cgen.generateAllConversionFcns(topicTypes, buildDir, model);

        % Update buildInfo
        headers = conversionFiles.HeaderFiles;
        for i=1:numel(headers)
            buildInfo.addIncludeFiles(headers{i});
        end

    end
end
