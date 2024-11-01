class PdfModelObject {
    [PSCustomObject]$model = @{}

    PdfModelObject($requestObject) {

        $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($requestObject.ContextPath)
        $tmpFolder = "$($requestObject.Settings.tmpFolder)/$($contextFileName)"
        # $pdfCache = $requestObject.Settings.pdfCache ?? $false
        if ($tmpFolder) {
            if (Test-Path -LiteralPath $tmpFolder) {
                $tmpFolder = Resolve-Path -LiteralPath $tmpFolder
            } else {
                $tmpFolder = New-Item -ItemType Directory -Path $tmpFolder

                # $preCoverPath = "$($tmpFolder)\$($contextFileName)"
                # $coverPath = "$($coverFolder)\$($contextFileName).jpg"
                
                $toolsFolder = $requestObject.Settings.toolsFolder
                $pdfToHtmlCli = Resolve-Path -LiteralPath "$toolsFolder\pdftohtml.exe"
            
                Write-Host "!!!!Pdf Context Path: $($requestObject.ContextPath)"
                Write-Host "!!!!Pdf Temp Folder: $($tmpFolder)"
                # Write-Host "!!!!Pdf Cover Path: $($coverPath)"
                # write-host "Cover cache: $($coverCache)"
                Write-Host "pdfToHtmlCli: $($pdfToHtmlCli)"
            
                & $pdfToHtmlCli -overwrite -embedbackground -embedfonts -skipinvisible $requestObject.ContextPath $tmpFolder
            }
        }

        $tocItems = $Null
        if (Test-Path -LiteralPath $tmpFolder) {
            # open index.html file from $tmpFolder
            $indexHtml = "$($tmpFolder)\index.html"

            # Find the navigation file
            $tocItems = Get-Content $indexHtml | Select-String -Pattern "<a href=`"(.+?)`".*?>(.+?)</a>" -AllMatches | ForEach-Object {
                $_.Matches | ForEach-Object {
                    $url = $_.Groups[1].Value
                    $relUrlPath = $requestObject.LocalPath + "/" + $url
                    $name = $_.Groups[2].Value
                    New-Object -TypeName PSObject -Property @{
                        Name = $name
                        Url = $relUrlPath
                    }
                }
            }
            Write-Host "!!!!Pdf Toc Items: $($tocItems)"
        
            # # Read the navigation file content
            # $navStream = $navEntry.Open()
            # $navReader = [System.IO.StreamReader]::new($navStream)
            # $navContent = $navReader.ReadToEnd()

            # # Close streams
            # $navReader.Close()
            # $navStream.Close()
        
            # # Parse the navigation file to extract TOC
            # $namespace = @{ ncx = "http://www.daisy.org/z3986/2005/ncx/" }
            # $tocItems = $navContent | Select-Xml -XPath "//ncx:navPoint" -Namespace $namespace | ForEach-Object {
            #     $navPoint = $_.Node
            #     $name = $navPoint.navLabel.text
            #     $url = $navPoint.content.src
            #     $id = $navPoint.id
            #     New-Object -TypeName PSObject -Property @{
            #         Name = $name
            #         Url = $url
            #         Id = $id
            #     }
            # }
        }
        
        $this.model = @{
            # type = "file"
            type = "list"
            category = "pdf"
            pageTemplate = "pdfish"
            url = $requestObject.localPath
            items = $tocItems
        }
    }
}