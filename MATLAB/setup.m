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

    % Add required subfolders to path
    addpath([basePath, '\\util']);
    addpath([basePath, '\\simpleAR\\scripts']);
    addpath([basePath, '\\simpleAR\\functions']);
    addpath([basePath, '\\spectralPeakDetection\\scripts']);
    addpath([basePath, '\\spectralPeakDetection\\functions']);

    disp('Setup complete.');
end