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

        $coverFolder = $requestObject.Settings.coverFolder
        $coverCache = $requestObject.Settings.coverCache
        if ($coverFolder) {
            $coverFolder = Resolve-Path -LiteralPath $coverFolder
        }

        $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($requestObject.ContextPath)
        $coverPath = "$($coverFolder)\$($contextFileName).jpg"

        write-host "!!!!Cover Container Path: $($coverPath)"        
        write-host "Cover cache: $($coverCache)"

        $bytes = $Null
        if (-not (Test-Path -LiteralPath $coverPath)) {
            Write-Host "Cover Cache Not Found: $coverPath"
            $bytes = $this.GetCoverFromZipContent($requestObject.ContextPath, $coverPath, $coverCache)
        }

        if ($coverCache -and (Test-Path -LiteralPath $coverPath)) {
            Write-Host "Cover Cache Enabled: $coverPath"
            $this.response.FilePath = $coverPath
        } elseif (Test-Path -LiteralPath $coverPath) {
            Write-Host "Cover Cache Disabled but Found nonetheless: $coverPath"
            $this.response.FilePath = $coverPath
        } else {
            Write-Host "Cover Cache Disabled"
            $this.response.ResponseBytes = $bytes
        }

        $this.response.ContentType = "image/jpeg"
        $this.response.ResponseString = $Null
        $this.response.Respond()
    }

    [PSCustomObject]GetCoverFromZipContent([string]$Path,[string]$coverPath,[bool]$coverCache) {
        write-host "!!!!Request Object: $($Path)"
        $zipFile = [System.IO.Compression.ZipFile]::OpenRead("$Path")        
        $bytes = $Null
        $firstItem = $true;
        $zipFile.Entries | Where-Object { $_.FullName -notlike "__MACOSX*" -and $_.FullName -notlike "*/" } | ForEach-Object {
            $entry = $_
            # Get cover image
            if ($firstItem) {
                $stream = $entry.Open()
                $memoryStream = New-Object System.IO.MemoryStream
                $stream.CopyTo($memoryStream)

                # test image start
                $coverWidth = 120
                $coverHeight = 120
                $originalImage = [System.Drawing.Image]::FromStream($memoryStream)
                $coverImage = $originalImage.GetThumbnailImage($coverWidth, $coverHeight, $null, [IntPtr]::Zero)

                if ($coverCache) {
                    write-host "!!!!Cover Container Path: $($coverPath)"
                    $coverImage.Save($coverPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                } else {
                    $coverStream = New-Object System.IO.MemoryStream
                    $coverImage.Save($coverStream, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                    $bytes = $coverStream.ToArray()
                    $coverStream.Dispose()
                }

                $coverImage.Dispose()
                $originalImage.Dispose()                
                $memoryStream.Close()
                $stream.Close()
                
                $firstItem = $false
            }
        }
        Write-Host "dispose zipfile"
        $zipFile.Dispose()
        return $bytes
    }
}
