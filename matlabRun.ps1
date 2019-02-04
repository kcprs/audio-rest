# Filename of the script is passed from VS Code
$scriptName = $args[0]

# Running filename as command opens the script in MATLAB
Invoke-Expression ".\$scriptName"

# Give MATLAB one second to open the script and
# send F5 keystroke to run.
$wshell = New-Object -ComObject wscript.shell;
Start-Sleep 1
$wshell.SendKeys('{F5}')