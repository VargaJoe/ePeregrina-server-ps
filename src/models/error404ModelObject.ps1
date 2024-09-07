class Error404ModelObject {
    [PSCustomObject]$model = @{}

    Error404ModelObject($requestObject) {
        $this.model = @{
            type = "error"
            category = "404"
            text = "404"
        }
    }
}