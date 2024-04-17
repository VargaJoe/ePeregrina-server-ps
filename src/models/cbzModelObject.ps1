class CbzModelObject {
    [PSCustomObject]$model = @{}

    CbzModelObject($requestObject) {
        $this.model = @{
            category = "cbz"
            items = $this.GetZipContents($requestObject.ContextPath) | ForEach-Object {
                $relUrlPath = $requestObject.LocalPath + "/" + "$($_.FullName)"
        
                # Create a custom object
                New-Object PSObject -Property @{
                    Name = $_.FullName 
                    Url = $relUrlPath
                }
            }
        }
    }

    [PSCustomObject]GetZipContents([string]$Path) {
        $zipFile = [System.IO.Compression.ZipFile]::OpenRead("$Path")
        $result = $zipFile.Entries | Where-Object { $_.FullName -notlike "__MACOSX*" -and $_.FullName -notlike "*/" }
        $zipFile.Dispose()
        return $result
    }
}
