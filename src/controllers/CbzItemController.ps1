function Show-CbzItemController($requestObject) {

    # Create model
     $model = @{
         category = "image"
         image = Get-ImageDataFromZip -ZipFilePath $requestObject.ContextPath -ImageName $requestObject.VirtualPath.TrimStart('/')
     }

     Show-View $requestObject "image" $model 
}

function Get-ImageDataFromZip {
    param (
        [string]$ZipFilePath,
        [string]$ImageName
    )

    $fileContent = Get-ZipFileContent -ZipFilePath $ZipFilePath -FileName $ImageName
    $imageContent = [System.Convert]::ToBase64String($fileContent)

    $imageModel = [PSCustomObject]@{
        Name = $ImageName
        Data = $imageContent
    }

    return $imageModel
}

function Get-ZipFileContent {
    param (
        [string]$ZipFilePath,
        [string]$FileName
    )

    $zipFile = [System.IO.Compression.ZipFile]::OpenRead($ZipFilePath)
    $entry = $zipFile.GetEntry($FileName)

    if ($null -eq $entry) {
        Write-Host "File '$FileName' not found in the zip archive."
        return
    }

    $stream = $entry.Open()
    $memoryStream = New-Object System.IO.MemoryStream
    $stream.CopyTo($memoryStream)

    $memoryStream.Position = 0
    $bytes = $memoryStream.ToArray()

    $stream.Close()
    $memoryStream.Close()
    $zipFile.Dispose()

    return $bytes
}