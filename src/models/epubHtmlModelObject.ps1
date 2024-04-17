class epubHtmlModelObject {
    [PSCustomObject]$model = @{}
    
    epubHtmlModelObject($requestObject) {
        Write-Host "HTML MODEL - Html from zip file"
        Write-Host "1" $requestObject.HttpRequest.RawUrl
        Write-Host "2" $requestObject.HttpRequest.Url
        $selectedPage = $requestObject.VirtualPath.TrimStart('/') 
        $htmlObj = $this.GetImageDataWithPagerFromZip($requestObject.ContextPath, $selectedPage)
        if ($null -eq $htmlObj.Data) {
            $this.model = @{
                type = "error"
                text = "404"
            }
            return
        }
        Write-Host "A1" $selectedPage
        $currentIndex = $this.GetPagerIndex($selectedPage, $requestObject.HttpRequest.QueryString["hash"], $htmlObj.ToC)
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

    [PSCustomObject]GetPagerIndex([string]$fileName, [string]$hash, [object[]]$pagerItems) {
        $itemSrc = $fileName
        $currentPageIndex = -1
        if ($hash) {
            $itemSrc = $itemSrc + $hash
        }
        Write-Host "A2" $itemSrc
        foreach ($item in $pagerItems) {
            $currentPageIndex = $currentPageIndex + 1
            if ($item.ExtendedName -eq $itemSrc) {
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
        $toc = $navContent | Select-Xml -XPath "//ncx:navPoint" -Namespace $namespace | ForEach-Object {
            $navPoint = $_.Node
            $name = $navPoint.navLabel.text
            $src = $navPoint.content.src
            $src2 = $src -replace "#", "?hash="
            $relUrlPath = $requestObject.ReducedLocalPath + "/" + "$($src)"
            New-Object -TypeName PSObject -Property @{
                Name = $name
                ExtendedName = $src                
                Url = $relUrlPath
            }
        }
        # End of ToC

        # # TODO: Get the table of contents from toc.nvx not from entries!!!
        # $toc = $zipFile.Entries | Where-Object { $_.FullName -notlike "__MACOSX*" -and $_.FullName -notlike "*/" } | Where-Object { $_.FullName -match "\.(html|xhtml)$" } | Sort-Object FullName | ForEach-Object {
        #     $relUrlPath = $requestObject.ReducedLocalPath + "/" + "$($_.FullName)"
            
        #     # Create a custom object
        #     New-Object PSObject -Property @{
        #         Name = $_.FullName 
        #         Url  = $relUrlPath
        #     }
        # }   
        
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