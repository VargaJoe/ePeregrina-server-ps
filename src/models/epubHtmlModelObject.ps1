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
        $currentIndex = $this.GetPagerIndex($selectedPage, $requestObject.HttpRequest.QueryString["id"], $htmlObj.ToC)
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

    [PSCustomObject]GetPagerIndex([string]$fileName, [string]$id, [object[]]$pagerItems) {
        $currentPageIndex = -1
        foreach ($item in $pagerItems) {
            $currentPageIndex = $currentPageIndex + 1
            if (($id -and $item.Id -eq $id) -or ($id -eq "" -and $item.ExtendedName -eq $fileName)) {
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

        # Stat of ToC
        $navEntry = $zipFile.Entries | Where-Object { $_.Name -match "toc.ncx|nav.xhtml" } | Select-Object -First 1

        # Read the navigation file content
        $navStream = $navEntry.Open()
        $navReader = [System.IO.StreamReader]::new($navStream)
        $navContent = $navReader.ReadToEnd()

        # Close streams
        $navReader.Close()
        $navStream.Close()

        # Parse the navigation file to extract TOC
        $namespace = @{ ncx = "http://www.daisy.org/z3986/2005/ncx/" }
        $toc = $navContent | Select-Xml -XPath "//ncx:navPoint" -Namespace $namespace | Sort-Object { [int]$_.Node.playOrder } | ForEach-Object {
            $navPoint = $_.Node
            $name = $navPoint.navLabel.text
            $src = $navPoint.content.src -replace "#", "?id=$($navPoint.id)#"
            $relUrlPath = $requestObject.ReducedLocalPath + "/" + "$($src)"
            New-Object -TypeName PSObject -Property @{
                Name = $name
                ExtendedName = $src
                Url = $relUrlPath
                Id = $navPoint.id
            }
        }
        # End of ToC

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