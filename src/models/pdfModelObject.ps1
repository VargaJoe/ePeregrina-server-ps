class PdfModelObject {
    [PSCustomObject]$model = @{}

    PdfModelObject($requestObject) {
        $this.model = @{
            type = "file"
            category = "pdf"
            url = $requestObject.localPath
        }
    }
}