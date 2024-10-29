class CbzImageThumbnailModelObject {
    [PSCustomObject]$response

    CbzImageThumbnailModelObject($requestObject) {
        $typeName = "ResponseObject"
        if ([System.Management.Automation.PSTypeName]$typeName) {
            $this.response = New-Object -TypeName $typeName -ArgumentList $requestObject.HttpContext.Response
        }

        $this.response.ResponseType = "CbzImageThumbnailModelObject"
    }

    [void] GetResponse($requestObject) {
        Write-Host "Get Thumbnail Action Response"
        Show-Context

        $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($requestObject.ContextPath)
        $thumbnailPath = "$($requestObject.WebFolderPath)\Thumbnails\$($contextFileName).jpg"

        write-host "!!!!Thumbnail Container Path: $($thumbnailPath)"        

        $bytes = $Null
        if (-not (Test-Path -LiteralPath $thumbnailPath)) {
            $selectedImage = $requestObject.VirtualPath.TrimStart('/')
            $bytes = $this.GetThumbnailFromZipContent($requestObject.ContextPath, $selectedImage) 
        }

        $this.response.ContentType = "image/jpeg"
        $this.response.ResponseString = $Null
        $this.response.ResponseBytes = $bytes
        $this.response.Respond()
    }

    [PSCustomObject]GetThumbnailFromZipContent([string]$Path,[string]$FileName) {
        write-host "!!!!Request Object: $($Path)"
        $zipFile = [System.IO.Compression.ZipFile]::OpenRead("$Path")        
        $bytes = $Null
        $entry = $zipFile.GetEntry($FileName)

        $stream = $entry.Open()
        $memoryStream = New-Object System.IO.MemoryStream
        $stream.CopyTo($memoryStream)
        
        $thumbnailWidth = 120
        $thumbnailHeight = 120
        $originalImage = [System.Drawing.Image]::FromStream($memoryStream)
        $thumbnailImage = $originalImage.GetThumbnailImage($thumbnailWidth, $thumbnailHeight, $null, [IntPtr]::Zero)

        $thumbnailStream = New-Object System.IO.MemoryStream
        $thumbnailImage.Save($thumbnailStream, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $bytes = $thumbnailStream.ToArray()

        $thumbnailStream.Dispose()
        $thumbnailImage.Dispose()
        $originalImage.Dispose()
        $memoryStream.Close()
        $stream.Close()
        $zipFile.Dispose()
        return $bytes
    }
}
