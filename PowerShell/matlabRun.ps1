# Workspace path and script name is passed from VS Code
$workspacePath = $args[0]
$scriptName = $args[1]

# Change directory to workspace path
Set-Location $workspacePath

# Running file name as command opens the script in MATLAB
Invoke-Expression ".\$scriptName"

# Give MATLAB one second to open the script and
# send F5 keystroke to run.
$wshell = New-Object -ComObject wscript.shell;
Start-Sleep 1
$wshell.SendKeys('{F5}')