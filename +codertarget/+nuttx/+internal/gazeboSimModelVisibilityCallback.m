function returnValue = gazeboSimModelVisibilityCallback(hObj)
% gazeboSimModelVisibilityCallback sets the visibility for Vehicle models
% for Gazebo Simulation

% Copyright 2019 The MathWorks, Inc.

returnValue = 0;
hCS = hObj.getConfigSet() ;
if codertarget.target.isCoderTarget(hCS)
    periph_name = 'simulator';
    data = codertarget.data.getData(hObj);
    if isfield(data, periph_name)
        gazeboSelected = strcmp(data.(periph_name), "Gazebo");
        if(gazeboSelected)
            returnValue = 1;
        end
    end
end
end
