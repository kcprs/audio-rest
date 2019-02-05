# Workspace path is passed from VS Code
$workspacePath = $args[0]

# MATLAB command to be ran
$command = @"
addpath('$workspacePath');
import matlab.unittest.TestSuite;
run(TestSuite.fromFolder('.\tests'));
rmpath('$workspacePath');
"@

# Execute the command
matlab -nosplash -nodesktop -r $command