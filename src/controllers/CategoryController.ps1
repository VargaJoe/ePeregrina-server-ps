function Show-CategoryController($requestObject) {
    Write-Host "1 $($requestObject.Controller)"
    Write-Host "2 $($requestObject.Category)"
    Write-Host "index $($requestObject.FolderIndex)"
    Write-Host "root $($requestObject.FolderPath)"
    Write-Host "rel $($requestObject.RelativePath)"
    Write-Host "6 $($requestObject.VirtualPath)"
    Write-Host "abs $($requestObject.ContextPath)"

    # category container
    # Create model
    $model = @{
        category = "books"
        items = Get-ChildItem -Path $requestObject.ContextPath | ForEach-Object {
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
