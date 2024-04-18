# load settings from settings.json
$sourceSettings = Get-Content -Raw -Path settings.json | ConvertFrom-Json
$sharedPaths = @()

$sfi = 0
foreach ($sharedPath in $sourceSettings.PSObject.Properties | Where-Object {$_.Name -like "*Paths"}) {
    Write-Host "Category" $sharedPath.Name
    for ($i = 0; $i -lt $sharedPath.Value.Count; $i++) {
        $pathString = $sharedPath.Value[$i].pathString
        if (Test-Path $pathString) {
            Write-Host "Exists $pathString"
            $absPath = Resolve-Path -LiteralPath $pathString
            $sharedPaths += $absPath 
            $shdName = "shared" + ($sfi++).ToString("D3")
            $sharedPath.Value[$i].pathString = "/shared/$shdName"
        }        
    }
}
$sourceSettings | ConvertTo-Json | Set-Content -Path settings-docker.json
$dockerSettingsPath = Resolve-Path -LiteralPath "./settings-docker.json"

foreach ($sharedPath in $sharedPaths) {
    Write-Host "Shared path: $sharedPath"    
}

$execFile = "docker"
$params = "run", "--rm", "-p", "38888:8888", "-d", "eol",
        "--name", "pelegrina-app", "eol",
        "-v", "$($dockerSettingsPath):/app/settings.json", "eol"

        $sfi = 0
        foreach ($sharedPath in $sharedPaths) {
            $shdName = "shared" + ($sfi++).ToString("D3")
            $params += "-v", "$($sharedPath):/shared/$shdName", "eol"
        }

        $params += "pelegrina-app"

Write-Host "Running docker command"
Write-Host "$execFile $($params -replace "eol", "$($eolChar)`r`n`t")"
& $execFile $($params | where-object {$_ -ne "eol"})
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error in executing $execFile"
}
