function Show-PdfController($requestObject) {
    Write-Host "pdf controller"
    Show-Context

    # Create model
    $model = @{
        category = "pdf"
        url = $requestObject.localPath
    }

    Show-View $requestObject "embed" $model
}
