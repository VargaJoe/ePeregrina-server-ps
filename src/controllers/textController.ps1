function Show-TextController($requestObject) {
    Write-Host "text controller"
    Show-Context

    # Write-Host "1 $($requestObject.Controller)"
    # Write-Host "2 $($requestObject.Category)"
    # Write-Host "index $($requestObject.FolderIndex)"
    # Write-Host "root $($requestObject.FolderPath)"
    # Write-Host "rel $($requestObject.RelativePath)"
    # Write-Host "6 $($requestObject.VirtualPath)"
    # Write-Host "abs $($requestObject.ContextPath)"

    # Create model
    $model = @{
        category = "text"
        textFile = Get-FileData -FilePath $requestObject.ContextPath
    }

    Show-View $requestObject "text" $model
}

function Get-FileData {
    param (
        [string]$FilePath
    )

    $fileName = [System.IO.Path]::GetFileName($FilePath)
    $fileContent = Get-Content -Path $FilePath -Raw 
    if ($fileContent.Contains("�")) {
        # convert to latin-2
        $fileContent = Get-Content -Path $FilePath -Raw -Encoding ISO-8859-2
    }
    
    $fileContent = $fileContent -replace "`r`n", "<br/>"
    
    $fileModel = [PSCustomObject]@{
        Name = $fileName
        Data = $fileContent
    }

    return $fileModel
}
