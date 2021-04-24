function onAfterCodeGen(hCS, buildInfo)

    nuttx.internal.cgen.postCodeGenHook(hCS, buildInfo);
    
    nuttx_ec.CreateCMakelist(hCS, buildInfo);

end