function Show-BooksController($requestObject) {
    Write-Output "paths: $($requestObject.Paths)"
    $folderIndex = [int]$($requestObject.Paths[2]) ?? 0;
    if ($requestObject.Paths.count -gt 3) {
        $relServerPath = ($requestObject.Paths[3..($requestObject.Paths.Count - 1)]) -join '/'
    } else {
        $relServerPath = ""
    }
    $rootPath = $($requestObject.Settings.booksPaths[$folderIndex].pathString)
    if (Test-Path -Path $rootPath) {
        $rootPath = Resolve-Path -Path $rootPath
    } 
    $absServerPath = "$rootPath/$relServerPath"
    
    Write-Output "index: $folderIndex"
    Write-Output "rel: $relServerPath"
    Write-Output "root: $rootPath"
    Write-Output "on server should be at: $absServerPath"
    
    # Create model
    $model = @{
        "category" = "books"
        "items" = Get-ChildItem -Path $absServerPath | ForEach-Object {
            $relUrlPath = "/" + $requestObject.Paths[1] + "/" + $folderIndex + $_.FullName.Replace($rootPath, "").Replace("\", "/")
            if (-not $_.PSIsContainer) { 
                $relUrlPath += "/view"
            }
    
            # Create a custom object
            New-Object PSObject -Property @{
                Name = $_.BaseName
                Url = $relUrlPath
            }
        }
    }

    Show-View $requestObject "category" $model
}