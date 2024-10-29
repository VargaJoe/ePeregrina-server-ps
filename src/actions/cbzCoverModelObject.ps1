class CbzCoverModelObject {
    [PSCustomObject]$response

    CbzCoverModelObject($requestObject) {
        $typeName = "ResponseObject"
        if ([System.Management.Automation.PSTypeName]$typeName) {
            $this.response = New-Object -TypeName $typeName -ArgumentList $requestObject.HttpContext.Response
        }

        $this.response.ResponseType = "CbzCoverModelObject"
    }

    [void] GetResponse($requestObject) {
        Write-Host "Get Cover Action Response"
        Show-Context

        $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($requestObject.ContextPath)
        $coverPath = "$($requestObject.WebFolderPath)\covers\$($contextFileName).jpg"

        write-host "!!!!Cover Container Path: $($coverPath)"        

        if (-not (Test-Path -LiteralPath $coverPath)) {
            $this.GetCoverFromZipContent($requestObject.ContextPath)
        }

        $this.response.ContentType = "image/jpeg"
        $this.response.ResponseString = $Null
        $this.response.FilePath = $coverPath       
        $this.response.Respond()
    }

    [PSCustomObject]GetCoverFromZipContent([string]$Path) {
        write-host "!!!!Request Object: $($Path)"
        $zipFile = [System.IO.Compression.ZipFile]::OpenRead("$Path")        
        $firstItem = $true;
        $result = $zipFile.Entries | Where-Object { $_.FullName -notlike "__MACOSX*" -and $_.FullName -notlike "*/" } | ForEach-Object {
            $entry = $_
            # Get cover image
            if ($firstItem) {
                $stream = $entry.Open()
                $memoryStream = New-Object System.IO.MemoryStream
                $stream.CopyTo($memoryStream)

                # $memoryStream.Position = 0
                # $bytes = $memoryStream.ToArray()

                # test image start
                $thumbnailWidth = 120
                $thumbnailHeight = 120
                $originalImage = [System.Drawing.Image]::FromStream($memoryStream)
                $thumbnailImage = $originalImage.GetThumbnailImage($thumbnailWidth, $thumbnailHeight, $null, [IntPtr]::Zero)
                $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($requestObject.ContextPath)
                $thumbnailContainerPath = "$($requestObject.WebFolderPath)\covers\$($contextFileName).jpg"
                write-host "!!!!Cover Container Path: $($thumbnailContainerPath)"
                $thumbnailImage.Save($thumbnailContainerPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

                $stream.Close()
                $memoryStream.Close()
                $originalImage.Dispose()
                $thumbnailImage.Dispose()
                
                $firstItem = $false
            }
        }
        Write-Host "dispose zipfile"
        $zipFile.Dispose()
        return $result
    }
}
