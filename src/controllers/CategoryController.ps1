function Show-CategoryController($requestObject) {
    Write-Host "category controller"
    Show-Context

    # category container
    # Create model
    $model = @{
        category = "books"
        items = Get-ChildItem -LiteralPath $requestObject.ContextPath | ForEach-Object {
            # $relUrlPath = "/" + $requestObject.Paths[1] + "/" + $folderIndex + $_.FullName.Replace($rootPath, "").Replace("\", "/")
            # $relUrlPath = $requestObject.RelativePath + "/" + $_.FullName.Replace($requestObject.FolderPath, "").Replace("\", "/")
            $relUrlPath = "/" + $requestObject.Category + "/" + $requestObject.FolderIndex + $_.FullName.Replace($requestObject.FolderPathResolved, "").Replace("\", "/")

            # if (-not $_.PSIsContainer) { 
            #     $relUrlPath += "/view"
            # }
    
            # Create a custom object
            New-Object PSObject -Property @{
                Name = $_.BaseName
                Url = $relUrlPath
            }
        }
    }

    Show-View $requestObject "category" $model
}
