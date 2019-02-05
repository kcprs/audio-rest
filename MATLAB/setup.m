function setup(basePath)
    if nargin == 0
        basePath = ".";
    end

    % Add subfolders to path
    addpath(basePath + "\util");
    addpath(basePath + "\linearAR");

    disp('Setup complete.');
end