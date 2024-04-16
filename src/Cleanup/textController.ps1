function Show-TextController($requestObject) {
    Write-Host "text controller"
    Show-Context

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
    $fileContent = Get-Content -LiteralPath $FilePath -Raw 
    if ($fileContent.Contains("�")) {
        # convert to latin-2
        $fileContent = Get-Content -LiteralPath $FilePath -Raw -Encoding ISO-8859-2
    }
    
    $fileContent = $fileContent -replace "`r`n", "<br/>"
    
    $fileModel = [PSCustomObject]@{
        Name = $fileName
        Data = $fileContent
    }

    return $fileModel
}
