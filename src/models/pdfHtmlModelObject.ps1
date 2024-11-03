class pdfHtmlModelObject {
    [PSCustomObject]$model = @{}
    
    pdfHtmlModelObject($requestObject) {
        Write-Host "HTML MODEL - Html from pdf file"
        $selectedPage = $requestObject.VirtualPath.TrimStart('/') 
        $htmlObj = $this.GetImageDataWithPagerFromPdf($requestObject, $selectedPage)
        if ($null -eq $htmlObj.Data) {
            $this.model = @{
                type = "error"
                text = "404"
            }
            return
        }
        
        Write-Host "!?!? Selected Page: $selectedPage"
        Write-Host "!?!? Pager Items Count: $($htmlObj.ToC.Count)"

        $currentIndex = $this.GetPagerIndex($selectedPage, $requestObject.HttpRequest.QueryString["id"], $htmlObj.ToC)
        Write-Host "!?!? Current Index: $currentIndex"

        $prevIndex = $currentIndex - 1
        $nextIndex = $currentIndex + 1

        Write-Host "!?!? Prev Index: $prevIndex - Next Index: $nextIndex"
        Write-Host "!?!? Prev Index: $($htmlObj.ToC[$prevIndex].Url) - Next Index: $($htmlObj.ToC[$nextIndex].Url)"
        $this.model = @{
            type = "image"
            pageTemplate = "html"
            pager = @{
                prev = $prevIndex -ge 0 ? $htmlObj.ToC[$prevIndex] : $null
                next = $nextIndex -lt $htmlObj.ToC.Count ? $htmlObj.ToC[$nextIndex] : $null
            }
            htmlFile = @{
                Name = $selectedPage
                Data = $htmlObj.Data -replace "<(/?)(html|body|head)>", "<`$1div>" #-replace " style=", " oldstyle="
            }
        }    
    }

    [PSCustomObject]GetPagerIndex([string]$fileName, [string]$id, [object[]]$pagerItems) {
        $currentPageIndex = -1
        foreach ($item in $pagerItems) {
            $currentPageIndex = $currentPageIndex + 1
            Write-Host "!!!! Pager Item: $($item.ExtendedName) - $currentPageIndex - $fileName"
            # if (($id -and $item.Id -eq $id) -or ($id -eq "" -and $item.ExtendedName -eq $fileName)) {
            if (($id -and $item.Id -eq $id) -or ($id -eq "" -and $item.ExtendedName -eq $fileName)) {                
                break
            }
        }

        return $currentPageIndex
    }
    
    [PSCustomObject]GetImageDataWithPagerFromPdf([object]$requestObject, [string]$selectedPage) {
        # $zipObj = $this.GetZipFileContentWithPager($ZipFilePath, $selectedPage)
        $tocItems = $Null
        $fileContent = ""
        $tmpFolder = $requestObject.Settings.tmpFolder
        $pdfCache = $requestObject.Settings.pdfCache ?? $false
        
        $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($requestObject.ContextPath)
        $tmpFolder = "$($requestObject.Settings.tmpFolder)/$($contextFileName)"
        # $pdfCache = $requestObject.Settings.pdfCache ?? $false
        if ($tmpFolder) {
            if (Test-Path -LiteralPath $tmpFolder) {
                $tmpFolder = Resolve-Path -LiteralPath $tmpFolder
                $indexHtml = "$($tmpFolder)/index.html"

                # Find the navigation file
                $tocItems = Get-Content $indexHtml | Select-String -Pattern "<a href=`"(.+?)`".*?>(.+?)</a>" -AllMatches | ForEach-Object {
                    $_.Matches | ForEach-Object {
                        $url = $_.Groups[1].Value
                        $relUrlPath = $requestObject.ReducedLocalPath + "/" + "$($url)"
                        $name = $_.Groups[2].Value
                        New-Object -TypeName PSObject -Property @{
                            Name = $name
                            ExtendedName = $url
                            Url = $relUrlPath
                        }
                    }
                }
            }
        }

        Write-Host "!!!!Pdf Toc Items: $($tocItems.Count)"

        Write-Host "!!!! Selected Page: $selectedPage"
        $tmpSelectedPage = "$($tmpFolder)/$($selectedPage)"
        if (Test-Path -LiteralPath $tmpSelectedPage) {
            $tmpSelectedPage = Resolve-Path -LiteralPath $tmpSelectedPage

            # open and readtoend $tmpSelectedPage
            $reader = New-Object System.IO.StreamReader($tmpSelectedPage)
            $fileContent = $reader.ReadToEnd()
            $reader.Close()
        }

        $imageModel = [PSCustomObject]@{
            Name = $selectedPage
            ToC  = $tocItems
            Data = $fileContent
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