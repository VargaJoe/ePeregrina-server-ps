class CbzImageModelObject {
    [PSCustomObject]$model = @{}
    
    CbzImageModelObject($requestObject) {
        Write-Host "CBZ MODEL - Image from zip file"
        $selectedImage = $requestObject.VirtualPath.TrimStart('/')
        $imgObj = $this.GetImageDataWithPagerFromZip($requestObject.ContextPath, $selectedImage)
        if ($null -eq $imgObj) {
            $this.model = @{
                type = "error"
                text = "404"
            }
            return
        }
        
        $currentIndex = $this.GetPagerIndex($selectedImage, $imgObj.ToC)
        $prevIndex = $currentIndex - 1
        $nextIndex = $currentIndex + 1
        $this.model = @{
            type = "image"
            pager = @{
                prev = $prevIndex -ge 0 ? $imgObj.ToC[$prevIndex] : $null
                next = $nextIndex -lt $imgObj.ToC.Count ? $imgObj.ToC[$nextIndex] : $null
            }
            image = @{
                Name = $selectedImage
                Data = $imgObj.Data
            }
        }    
    }

    [PSCustomObject]GetPagerIndex([string]$imageName, [object[]]$pagerItems) {
        $currentPageIndex = -1

        foreach ($item in $pagerItems) {
            $currentPageIndex = $currentPageIndex + 1
            if ($item.Name -eq $ImageName) {
                break
            } 
        }

        return $currentPageIndex
    }
    
    [PSCustomObject]GetImageDataWithPagerFromZip([string]$ZipFilePath, [string]$ImageName) {
        $zipObj = $this.GetZipFileContentWithPager($ZipFilePath, $ImageName)
        if ($null -eq $zipObj.bytes) {
            return $null
        }
        $imageContent = [System.Convert]::ToBase64String($zipObj.bytes)
        $imageModel = [PSCustomObject]@{
            Name = $ImageName
            ToC  = $zipObj.toc
            Data = $imageContent
        }
    
        return $imageModel
    }

    [PSCustomObject]GetZipFileContentWithPager([string]$ZipFilePath,[string]$FileName) {
        $zipFile = [System.IO.Compression.ZipFile]::OpenRead($ZipFilePath)
        $toc = $zipFile.Entries | Where-Object { $_.FullName -notlike "__MACOSX*" -and $_.FullName -notlike "*/" } | ForEach-Object {
            $relUrlPath = $requestObject.ReducedLocalPath + "/" + "$($_.FullName)"
            
            # Create a custom object
            New-Object PSObject -Property @{
                Name = $_.FullName 
                Url  = $relUrlPath
            }
        }   
        
        $entry = $zipFile.GetEntry($FileName)
    
        if ($null -eq $entry) {
            Write-Host "File '$FileName' not found in the zip archive."
            return @{ 
                toc = $toc
                bytes = $null
            }
        }
    
        $stream = $entry.Open()
        $memoryStream = New-Object System.IO.MemoryStream
        $stream.CopyTo($memoryStream)
    
        $memoryStream.Position = 0
        $bytes = $memoryStream.ToArray()
    
        $stream.Close()
        $memoryStream.Close()
        $zipFile.Dispose()
    
        return @{ 
            toc = $toc
            bytes = $bytes
        }
    }
}