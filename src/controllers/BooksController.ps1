function Show-BooksController($requestObject) {
    Write-Output "$($requestObject.Settings.booksPaths[0].pathString)"
    $rootPath = $($requestObject.Settings.booksPaths[0].pathString)

    $items = Get-ChildItem -Path $rootPath -Recurse

    foreach ($item in $items) {
        Write-Output $item.FullName
    }

    Show-View $requestObject "category"
}
