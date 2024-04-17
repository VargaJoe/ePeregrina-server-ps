class EpubModelObject {
    [PSCustomObject]$model = @{}

    EpubModelObject($requestObject) {
        $this.model = @{
            category = "epub"
            items = $this.GetEpubTableOfContents($requestObject.ContextPath) | ForEach-Object {
               $relUrlPath = $requestObject.LocalPath + "/" + "$($_.Url)"
       
               # Create a custom object
               New-Object PSObject -Property @{
                   Name = $_.Name 
                   Url = $relUrlPath
               }
           }
        }
    }

    [PSCustomObject]GetEpubTableOfContents([string]$EpubFilePath) {
        # Load EPUB file into memory
        $epubBytes = [System.IO.File]::ReadAllBytes($EpubFilePath)
    
        # Create a ZipArchive object from the EPUB file bytes
        $zipStream = New-Object System.IO.MemoryStream -ArgumentList @(,$epubBytes)
        $zipArchive = New-Object System.IO.Compression.ZipArchive($zipStream)
    
        # Find the navigation file
        $navEntry = $zipArchive.Entries | Where-Object { $_.Name -match "toc.ncx|nav.xhtml" } | Select-Object -First 1
    
        # Read the navigation file content
        $navStream = $navEntry.Open()
        $navReader = [System.IO.StreamReader]::new($navStream)
        $navContent = $navReader.ReadToEnd()

        # Close streams
        $navReader.Close()
        $navStream.Close()
    
        # Parse the navigation file to extract TOC
        $namespace = @{ ncx = "http://www.daisy.org/z3986/2005/ncx/" }
        $tocItems = $navContent | Select-Xml -XPath "//ncx:navPoint" -Namespace $namespace | ForEach-Object {
            $navPoint = $_.Node
            $name = $navPoint.navLabel.text
            $url = $navPoint.content.src
            New-Object -TypeName PSObject -Property @{
                Name = $name
                Url = $url
            }
        }

        # Dispose of the ZipArchive and MemoryStream
        $zipArchive.Dispose()
        $zipStream.Dispose()
    
        return $tocItems
    }
}
