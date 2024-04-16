class PdfModelObject {
    [PSCustomObject]$model = @{}

    PdfModelObject($requestObject) {
        $this.model = @{
            category = "pdf"
            url = $requestObject.localPath
        }
    }
}