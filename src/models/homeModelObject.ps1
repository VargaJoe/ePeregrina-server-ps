class HomeModelObject {
    [PSCustomObject]$model = @{}

    HomeModelObject($requestObject) {
        $odd = $true
        $this.model = @{
            type = "list"
            category = "index"
            items = $requestObject.Settings.PSObject.Properties | Where-Object { $_.Value -is [Object[]] -and $null -ne $_.Value[0].pathString } | ForEach-Object {
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
    }
}