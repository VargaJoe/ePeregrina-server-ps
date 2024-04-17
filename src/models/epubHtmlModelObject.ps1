class epubHtmlModelObject {
    [PSCustomObject]$model = @{}
    
    epubHtmlModelObject($requestObject) {
        Write-Host "HTML MODEL - Html from zip file"
        $selectedPage = $requestObject.VirtualPath.TrimStart('/')
        $htmlObj = $this.GetImageDataWithPagerFromZip($requestObject.ContextPath, $selectedPage)
        if ($null -eq $htmlObj.Data) {
            $this.model = @{
                type = "error"
                text = "404"
            }
            return
        }


        $currentIndex = $this.GetPagerIndex($selectedPage, $htmlObj.ToC)
        $prevIndex = $currentIndex - 1
        $nextIndex = $currentIndex + 1
        $this.model = @{
            type = "image"
            pager = @{
                prev = $prevIndex -ge 0 ? $htmlObj.ToC[$prevIndex] : $null
                next = $nextIndex -lt $htmlObj.ToC.Count ? $htmlObj.ToC[$nextIndex] : $null
            }
            htmlFile = @{
                Name = $selectedPage
                Data = $htmlObj.Data -replace "<(/?)(html|body|head)>", "<`$1div>"
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
        $imageModel = [PSCustomObject]@{
            Name = $ImageName
            ToC  = $zipObj.toc
            Data = $zipObj.data
        }
    
        return $imageModel
    }

    [PSCustomObject]GetZipFileContentWithPager([string]$ZipFilePath,[string]$FileName) {
        $zipFile = [System.IO.Compression.ZipFile]::OpenRead($ZipFilePath)
        $toc = $zipFile.Entries | Where-Object { $_.FullName -notlike "__MACOSX*" -and $_.FullName -notlike "*/" } | Sort-Object FullName | ForEach-Object {
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
                data = $null
            }
        }

        $stream = $entry.Open()
        $reader = New-Object System.IO.StreamReader($stream)
        $fileContent = $reader.ReadToEnd()

        $reader.Close()
        $stream.Close()
        $zipFile.Dispose()

        return @{
            toc = $toc
            data = $fileContent
        }
    }
}