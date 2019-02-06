param (
    [switch]$exit = $false
)

# MATLAB command to be ran
$command = @"
addpath('.\MATLAB');
setup('.\MATLAB');
import matlab.unittest.TestSuite;
result = run(TestSuite.fromFolder('.\MATLAB\tests'));
"@

# Additional command for exiting MATLAB
$exitCommand = @"
testingSucceeded = true;
for i = 1:length(result)
    if result(i).Passed ~= 1
        testingSucceeded = false;
        break;
    end
end

if testingSucceeded 
    exit(100);
end
"@

# Add exit command if exit argument given
if ($exit) {
    $command += $exitCommand
}


# Execute the command
Write-Host "Running test suite..." -ForegroundColor green
matlab -nosplash -nodesktop -wait -r $command

# Return MATLAB exit code if exiting
if ($exit) {
    return $LASTEXITCODE
}