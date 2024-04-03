function Show-ComicsController($requestObject) {
    Write-Output "$($requestObject.Settings.comicsPaths[0].pathString)"
    $rootPath = $($requestObject.Settings.comicsPaths[0].pathString)
    
    $items = Get-ChildItem -Path $rootPath -Recurse

    foreach ($item in $items) {
        Write-Output $item.FullName
    }

    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    $response.ResponseType = "html"
    $response.FilePath = Resolve-Path "./index.html"
    $response.Respond()
}
