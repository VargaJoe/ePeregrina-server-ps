class PdfCoverModelObject {
    [PSCustomObject]$response

    PdfCoverModelObject($requestObject) {
        $typeName = "ResponseObject"
        if ([System.Management.Automation.PSTypeName]$typeName) {
            $this.response = New-Object -TypeName $typeName -ArgumentList $requestObject.HttpContext.Response
        }

        $this.response.ResponseType = "PdfCoverModelObject"
    }

    [void] GetResponse($requestObject) {
        Write-Host "Get Cover Action on Pdf Response"
        Show-Context

        $tmpFolder = $requestObject.Settings.tmpFolder
        $coverFolder = $requestObject.Settings.coverFolder
        $coverCache = $requestObject.Settings.coverCache
        if ($tmpFolder) {
            if (Test-Path -LiteralPath $tmpFolder) {
                $tmpFolder = Resolve-Path -LiteralPath $tmpFolder
            } else {
                $tmpFolder = New-Item -ItemType Directory -Path $tmpFolder
            }
        }
        if ($coverFolder) {
            if (Test-Path -LiteralPath $coverFolder) {
                $coverFolder = Resolve-Path -LiteralPath $coverFolder
            } else {
                $coverFolder = New-Item -ItemType Directory -Path $coverFolder
            }
        }

        $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($requestObject.ContextPath)
        $preCoverPath = "$($tmpFolder)\$($contextFileName)"
        $coverPath = "$($coverFolder)\$($contextFileName).jpg"
        
        $toolsFolder = $requestObject.Settings.toolsFolder
        $pdfImagesCli = Resolve-Path -LiteralPath "$toolsFolder\pdfimages.exe"

        Write-Host "!!!!Pdf Temp Cover PrePath: $($preCoverPath)"
        Write-Host "!!!!Pdf Cover Path: $($coverPath)"
        write-host "Cover cache: $($coverCache)"
        Write-Host "pdfImagesCli: $($pdfImagesCli)"

        $bytes = $Null
        if (-not (Test-Path -LiteralPath $coverPath)) {
            Write-Host "Cover Cache Not Found: $coverPath"
            $bytes = $this.GetCoverFromPdfContent($requestObject.ContextPath, $preCoverPath, $coverPath, $coverCache, $pdfImagesCli)
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

    [PSCustomObject]GetCoverFromPdfContent([string]$Path, [string]$preCoverPath, [string]$CoverPath, [bool]$coverCache, [string]$pdfImagesCli) {
        write-host "!!!!Request Object: $($Path)"
        $tmpCoverPath = "$($preCoverPath)-0000.jpg"
        $bytes = $null
        try {
            if (-not (Test-Path -LiteralPath $tmpCoverPath)) {
                Write-Host "Prepare Cover: $tmpCoverPath"
                # info: https://www.xpdfreader.com/pdfimages-man.html
                & $pdfImagesCli -j -l 1 $Path $preCoverPath    
            }           

            # TODO: file should be renamed and resized
            if (Test-Path -LiteralPath $tmpCoverPath) {
                $coverWidth = 120
                $coverHeight = 120
                $originalImage = [System.Drawing.Image]::FromFile($tmpCoverPath)
                $coverImage = $originalImage.GetThumbnailImage($coverWidth, $coverHeight, $null, [IntPtr]::Zero)

                if ($coverCache) {
                    write-host "!!!!Cover Container Path: $($coverPath)"
                    $coverImage.Save($coverPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                } else {
                    write-host "Show cover image from stream..."
                    $coverStream = New-Object System.IO.MemoryStream
                    $coverImage.Save($coverStream, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                    $bytes = $coverStream.ToArray()
                    $coverStream.Dispose()
                }
                
                $coverImage.Dispose()
                $originalImage.Dispose()                
            }            
        }
        catch {
            return $bytes
        }        

        return $bytes
    }
}
