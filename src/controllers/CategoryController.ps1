function Show-CategoryController($requestObject) {
    Write-Host "category controller"
    Show-Context

    if ($requestObject.paths.length -lt 3) {
        # category container
        # Create model
        $folderIndex = 0
        $allSharedFolder = $requestObject.Settings.PSObject.Properties | Where-Object { $_.Name -eq $requestObject.Category + "Paths" } | ForEach-Object {
            $_.Value | ForEach-Object {
                $FolderPathResolved = Resolve-Path -LiteralPath $_.pathString            
                Get-ChildItem -LiteralPath $_.pathString | ForEach-Object {
                    $relUrlPath = "/" + $requestObject.Category + "/" + $folderIndex + $_.FullName.Replace($FolderPathResolved, "").Replace("\", "/")
        
                    # Create a custom object
                    New-Object PSObject -Property @{
                        Name = $_.BaseName
                        Url = $relUrlPath
                    }
                }
                $folderIndex = $folderIndex + 1
            }
        } | Sort-Object Name
            

        $model = @{
            category = $requestObject.Category
            items = $allSharedFolder
        }
    } else {

        $model = @{
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
    
    }
    Show-View $requestObject "category" $model
}
