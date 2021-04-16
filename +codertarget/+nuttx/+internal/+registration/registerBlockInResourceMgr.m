function registerBlockInResourceMgr(blk, tagName)
%registerBlockInResourceMgr registers the block in resource manager

% Copyright 2021 The MathWorks, Inc.


if codertarget.nuttx.internal.registration.isInvalidRegisterUseCase(blk)
    return
end

if codertarget.resourcemanager.isblockregistered(blk)
    return
else
    codertarget.resourcemanager.registerblock(blk);
    codertarget.resourcemanager.increment(blk, tagName, 'num');
 end
    
end
