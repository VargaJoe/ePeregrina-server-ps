# Get the full path to the current script
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "program-async.ps1"

# Start a new instance of PowerShell and run the script in it
Start-Process -FilePath "pwsh" -ArgumentList "-NoExit", "-NoProfile", "-File `"$scriptPath`""
