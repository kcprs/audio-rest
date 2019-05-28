function setup(basePath)
    %SETUP Prepare current MATLAB workspace for work with this package
    %   SETUP() - Use this if the MATLAB folder from this package is
    %   the current working directory.
    %
    %   SETUP(basePath) - Use this if the folder called MATLAB is not
    %   the current working directory. Argument basePath should be the path
    %   to the MATLAB folder in this package.

    if nargin == 0
        basePath = '.';
    end

    % Set global variables
    global fsGlobal
    fsGlobal = 44100;

    global pathsAdded

    % Remove paths added by another setup
    for iter = 1:length(pathsAdded)
        rmpath(pathsAdded(iter))
    end

    % Define paths to add
    pathsAdded = [basePath + "\\audio";
            basePath + "\\classes";
            basePath + "\\functions";
            basePath + "\\scripts";
            basePath + "\\tests"];

    % Add required subfolders to path
    for iter = 1:length(pathsAdded)
        addpath(pathsAdded(iter))
    end

    disp('Setup complete.');

end
