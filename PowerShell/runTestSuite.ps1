# Workspace path is passed from VS Code
$workspacePath = $args[0]

# MATLAB command to be ran
$command = @"
addpath('$workspacePath\MATLAB');
setup('$workspacePath\MATLAB')
import matlab.unittest.TestSuite;
run(TestSuite.fromFolder('$workspacePath\MATLAB\tests'));
"@

# Execute the command
matlab -nosplash -nodesktop -r $command