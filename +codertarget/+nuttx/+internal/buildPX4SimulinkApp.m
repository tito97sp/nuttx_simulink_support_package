function buildPX4SimulinkApp(buildInfo)
%   Copyright 2020 The MathWorks, Inc.
NewInfraBuildComplete = true;
presentPath = pwd;
buildPath = px4.internal.util.CommonUtility.getPX4FirmwareBuildDir;
try 
    %We cd to the fw build folder because the path to the obj files, src
    %files, include paths in the compile/linker/binary generation commands
    %are relative to the build folder
cd(buildPath);
buildToolObj = px4.internal.build.buildToolConfigurationPX4.getInstance(buildInfo);
buildToolObj.compileFiles();
buildToolObj.createArchive();
buildToolObj.generateELF();
buildToolObj.generateBin();
buildToolObj.generatePX4();

cd(presentPath);
catch ME
    NewInfraBuildComplete = false;
    Exception = ME.message;
    warning(Exception);
    cd(presentPath);
    %Remove the below line for submission
%     error(Exception);
end
if(NewInfraBuildComplete)
    setenv('MW_PX4_NewInfraBuildComplete','True');
else
    setenv('MW_PX4_NewInfraBuildComplete','False');
end
end
