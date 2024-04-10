function Show-ItemController($requestObject) {
    Write-Host "1 $($requestObject.Controller)"
    Write-Host "2 $($requestObject.Category)"
    Write-Host "index $($requestObject.FolderIndex)"
    Write-Host "root $($requestObject.FolderPath)"
    Write-Host "rel $($requestObject.RelativePath)"
    Write-Host "6 $($requestObject.VirtualPath)"
    Write-Host "abs $($requestObject.ContextPath)"

    # Create model
    $model = @{
        category = "image"
        "image" = Get-ImageData -ImagePath $requestObject.ContextPath
    }

    Show-View $requestObject "image" $model
}

function Get-ImageData {
    param (
        [string]$ImagePath
    )

    $imageName = [System.IO.Path]::GetFileName($ImagePath)
    $imageContent = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ImagePath))

    $imageModel = [PSCustomObject]@{
        Name = $imageName
        Data = $imageContent
    }

    return $imageModel
}
