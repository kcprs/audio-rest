# Run testing suite and save MATLAB exit code
$exitCode = .\PowerShell\runTestSuite.ps1 -exit

# Allow or abort commit based on test results
if ($exitCode -eq 100) {
    Write-Host "Testing Successful." -ForegroundColor green
    exit 0
} else {
    Write-Host "Testing failed. Aborting commit." -ForegroundColor red
    exit -1
}