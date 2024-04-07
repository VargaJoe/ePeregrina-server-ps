function Show-ComicsController($requestObject) {
    Write-Output "paths: $($requestObject.Paths)"
    $folderIndex = [int]$($requestObject.Paths[2]) ?? 0;
    if ($requestObject.Paths.count -gt 3) {
        $paths = $requestObject.Paths[3..($requestObject.Paths.Count - 1)]

        # Check if the last part is "view" and remove it if it is
        if ($paths[-1] -eq "view") {
            $paths = $paths[0..($paths.Count - 2)]
        }

        $relServerPath = $paths -join '/'
    } else {
        $relServerPath = ""
    }
    $rootPath = $($requestObject.Settings.comicsPaths[$folderIndex].pathString)
    if (Test-Path -Path $rootPath) {
        $rootPath = Resolve-Path -Path $rootPath
    } 
    $absServerPath = "$rootPath/$relServerPath"
    
    Write-Output "index: $folderIndex"
    Write-Output "rel: $relServerPath"
    Write-Output "root: $rootPath"
    Write-Output "on server should be at: $absServerPath"

    if (-not ($requestObject.Paths[-1] -eq "view")) {
        # category container
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
    } else { 
        Write-Output "viewing image"
        $imageName = [System.IO.Path]::GetFileName($absServerPath)
        Write-Output "image: $imageName"
        $imageContent = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($absServerPath))
        Write-Output "image content: $imageContent"

        # Create model
        $model = @{
            "category" = "image"
            "image" = New-Object PSObject -Property @{
                Name = $imageName
                Data = $imageContent
            }           
        }
        write-output "model: $model"
        Show-View $requestObject "image" $model
        write-output "showed view"
    }
}

function Get-ImageData {
    param (
        [string]$ImagePath
    )

    if (-not (Test-Path $ImagePath)) {
        Write-Host "File not found: $ImagePath"
        return $null
    }

    $imageName = [System.IO.Path]::GetFileName($ImagePath)
    $imageContent = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ImagePath))

    $imageModel = [PSCustomObject]@{
        Name = $imageName
        Content = $imageContent
    }

    return $imageModel
}