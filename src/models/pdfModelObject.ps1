class PdfModelObject {
    [PSCustomObject]$model = @{}

    PdfModelObject($requestObject) {

        $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($requestObject.ContextPath)
        $tmpFolder = "$($requestObject.Settings.tmpFolder)/$($contextFileName)"
        $pdfCache = $requestObject.Settings.pdfCache ?? $false
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
        
        $this.model = @{
            type = "file"
            category = "pdf"
            pageTemplate = "pdfish"
            url = $requestObject.localPath
        }
    }
}