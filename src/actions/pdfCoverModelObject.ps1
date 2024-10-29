class PdfCoverModelObject {
    [PSCustomObject]$response

    PdfCoverModelObject($requestObject) {
        $typeName = "ResponseObject"
        if ([System.Management.Automation.PSTypeName]$typeName) {
            $this.response = New-Object -TypeName $typeName -ArgumentList $requestObject.HttpContext.Response
        }

        $this.response.ResponseType = "PdfCoverModelObject"
    }

    [void] GetResponse($requestObject) {
        Write-Host "Get Cover Action Response"
        Show-Context

        $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($requestObject.ContextPath)
        $coverPath = "$($requestObject.WebFolderPath)\covers\$($contextFileName)"
        $toolsFolder = $requestObject.Settings.toolsFolder
        $pdfImagesCli = Resolve-Path -LiteralPath "$toolsFolder\pdfimages.exe"

        Write-Host "!!!!Cover Path: $($coverPath)"
        Write-Host "pdfImagesCli: $($pdfImagesCli)"

        if (-not (Test-Path -LiteralPath $coverPath)) {
            $this.GetCoverFromPdfContent($requestObject.ContextPath, $coverPath, $pdfImagesCli)
        }

        # pdfImagesCli output naming workaround
        $coverPath = $coverPath + "-0000.jpg"
        Write-Host "!!!!Cover Path: $($coverPath)"

        $this.response.ContentType = "image/jpeg"
        $this.response.ResponseString = $Null
        $this.response.FilePath = $coverPath       
        $this.response.Respond()
    }

    [PSCustomObject]GetCoverFromPdfContent([string]$Path, [string]$coverPath, [string]$pdfImagesCli) {
        write-host "!!!!Request Object: $($Path)"
        try {
            # info: https://www.xpdfreader.com/pdfimages-man.html
            & $pdfImagesCli -j -l 1 $Path $coverPath

            # TODO: file should be renamed and resized
        }
        catch {
            return $false
        }        

        return $true
    }
}
