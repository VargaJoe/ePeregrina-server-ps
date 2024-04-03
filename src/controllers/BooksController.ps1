function Show-BooksController($requestObject) {
    Write-Output "$($requestObject.Settings.booksPaths[0].pathString)"
    $rootPath = $($requestObject.Settings.booksPaths[0].pathString)

    $items = Get-ChildItem -Path $rootPath -Recurse

    foreach ($item in $items) {
        Write-Output $item.FullName
    }

    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    $response.ResponseType = "html"
    $response.FilePath = Resolve-Path "./index.html"
    $response.Respond()
}
