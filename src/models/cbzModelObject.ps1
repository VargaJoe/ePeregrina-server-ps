class CbzModelObject {
    [PSCustomObject]$model = @{}

    CbzModelObject($requestObject) {
        $this.model = @{
            type = "list"
            category = "cbz"
            
            items = $this.GetZipContents($requestObject.ContextPath) 
        }
    }

    [PSCustomObject]GetZipContents([string]$Path) {
        write-host "!!!!Request Object: $($Path)"
        $zipFile = [System.IO.Compression.ZipFile]::OpenRead("$Path")        
        $result = $zipFile.Entries | Where-Object { $_.FullName -notlike "__MACOSX*" -and $_.FullName -notlike "*/" } | ForEach-Object {
            $entry = $_
            $relUrlPath = $requestObject.LocalPath + "/" + "$($entry.FullName)"

            # Create a custom object
            New-Object PSObject -Property @{
                Name = $_.FullName 
                Url  = $relUrlPath
                Cover = $requestObject.LocalPath + "?action=Cover"
                Thumbnail = $relUrlPath + "?action=Thumbnail"
            }
        }
        $zipFile.Dispose()
        return $result
    }
}
