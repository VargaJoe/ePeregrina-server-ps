function Show-CategoryFolderController($requestObject) {
    Write-Host "category folder controller"
    Show-Context

    $model = @{
        items = Get-ChildItem -LiteralPath $requestObject.ContextPath | ForEach-Object {
            $relUrlPath = "/" + $requestObject.Category + "/" + $requestObject.FolderIndex + $_.FullName.Replace($requestObject.FolderPathResolved, "").Replace("\", "/")

    
            # Create a custom object
            New-Object PSObject -Property @{
                Name = $_.BaseName
                Url = $relUrlPath
            }
        }
    }

    Show-View $requestObject "category" $model
}
