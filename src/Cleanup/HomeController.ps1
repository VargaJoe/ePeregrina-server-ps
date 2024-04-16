function Show-HomeController($requestObject) {
    Write-Host "home controller"
    Show-Context

    $odd = $true
    $model = @{
        category = "index"
        items = $requestObject.Settings.PSObject.Properties | Where-Object { $_.Value -is [Object[]] -and $_.Value[0].pathString -ne $null } | ForEach-Object {
            New-Object PSObject -Property @{
                name = $_.Name -replace "Paths", ""
                color =  $odd ? "orange" : "blue"
                url = "/" + $_.Name -replace "Paths", ""
                sharedPaths = $_.Value | ForEach-Object {
                    New-Object PSObject -Property @{
                        path = $_.pathString
                    }
                }
            }
            $odd = -not $odd
        }
    }

    Show-View $requestObject "index" $model
}
