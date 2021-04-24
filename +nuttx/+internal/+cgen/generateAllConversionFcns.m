function genfiles = generateAllConversionFcns(topicTypes,  destDir, model)
%This function is for internal use only. It may be removed in the future.

%generateAllConversionFcns - Generate & save header file for conversion between uORB Bus name and
% Simulink defined bus name for uORB<->Bus conversions

%   Copyright 2018-2020 The MathWorks, Inc.

    validateattributes('topicTypes', {'char', 'cell'}, {});
    validateattributes('destDir', {'char'}, {});

    cgenConstants = nuttx.internal.cgen.Constants;
    genCodeHeaderFile = cgenConstants.GeneratedCode.HeaderFile;

    hdrFileIncludesSection = StringWriter;
    hdrFileBodyDeclarations = StringWriter;

    for i=1:numel(topicTypes)
        topic = topicTypes{i} ;
        uORBHeaderFile = cgenConstants.getGenerateduORBHeader(topic);

        %     hdrFileIncludesSection.addcr(['#include <uORB/topics/' topic '.h>']);
        hdrFileIncludesSection.addcr(['#include ' uORBHeaderFile]);
    end

    for i=1:numel(topicTypes)
        topic = topicTypes{i} ;
        busName = nuttx.internal.bus.Util.uORBMsgTypeToBusName(topic, model);

        hdrFileBodyDeclarations.add('typedef struct');
        hdrFileBodyDeclarations.add(' ');

        hdrFileBodyDeclarations.add([topic '_s ']);
        hdrFileBodyDeclarations.add(' ');

        hdrFileBodyDeclarations.add(busName);
        hdrFileBodyDeclarations.add(' ');

        hdrFileBodyDeclarations.addcr(';');
    end

    headerFile = StringWriter;
    headerFile.add(hdrFileIncludesSection);
    headerFile.addcr;
    headerFile.add(hdrFileBodyDeclarations);
    nuttx.internal.cgen.insertHeaderGuards(headerFile, genCodeHeaderFile);

    headerFileFullName = fullfile(destDir, genCodeHeaderFile);
    headerFile.write(headerFileFullName);

    genfiles.HeaderFiles = { genCodeHeaderFile };

end
