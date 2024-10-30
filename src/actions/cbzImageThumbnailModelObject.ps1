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

        $thumbnailFolder = $requestObject.Settings.thumbnailFolder
        $thumbnailCache = $requestObject.Settings.thumbnailCache
        if ($thumbnailFolder) {
            $thumbnailFolder = Resolve-Path -LiteralPath $thumbnailFolder
        }

        $selectedImage = $requestObject.VirtualPath.TrimStart('/')
        $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($requestObject.ContextPath)
        $virtualFileName = [System.IO.Path]::GetFileNameWithoutExtension($selectedImage)
        $thumbnailPath = "$($thumbnailFolder)\$($contextFileName)-$($virtualFileName).jpg"
        
        write-host "!!!!Thumbnail Container Path: $($thumbnailPath)"
        write-host "thumbnail cache: $($thumbnailCache)"

        
        $bytes = $Null
        if (-not (Test-Path -LiteralPath $thumbnailPath)) {
            Write-Host "Thumbnail Cache Not Found: $thumbnailPath"
            $bytes = $this.GetThumbnailFromZipContent($requestObject.ContextPath, $selectedImage, $thumbnailPath, $thumbnailCache)
        }

        if ($thumbnailCache -and (Test-Path -LiteralPath $thumbnailPath)) {
            Write-Host "Thumbnail Cache Enabled: $thumbnailPath"
            $this.response.FilePath = $thumbnailPath
        } elseif (Test-Path -LiteralPath $thumbnailPath) {
            Write-Host "Thumbnail Cache Disabled but Found nonetheless: $thumbnailPath"
            $this.response.FilePath = $thumbnailPath
        } else {
            Write-Host "Thumbnail Cache Disabled"
            $this.response.ResponseBytes = $bytes
        }

        $this.response.ContentType = "image/jpeg"
        $this.response.ResponseString = $Null
        $this.response.Respond()
    }

    [PSCustomObject]GetThumbnailFromZipContent([string]$Path,[string]$FileName,[string]$thumbnailPath,[bool]$thumbnailCache) {
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

        if ($thumbnailCache) {
            write-host "!!!!Cover Container Path: $($thumbnailPath)"
            $thumbnailImage.Save($thumbnailPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        } else {
            $thumbnailStream = New-Object System.IO.MemoryStream
            $thumbnailImage.Save($thumbnailStream, [System.Drawing.Imaging.ImageFormat]::Jpeg)
            $bytes = $thumbnailStream.ToArray()
            $thumbnailStream.Dispose()
        }
        
        $thumbnailImage.Dispose()
        $originalImage.Dispose()
        $memoryStream.Close()
        $stream.Close()
        $zipFile.Dispose()
        return $bytes
    }
}
