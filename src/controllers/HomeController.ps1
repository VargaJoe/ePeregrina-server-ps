function Show-HomeController($requestObject) {
    Write-Output "1 $($requestObject.Settings.theme)"
    Write-Output "3 $($requestObject.Settings.WebFolder)"
    Write-Output "4 $($requestObject.Settings.comicsPaths[0].pathString)"
    Write-Output "5 $($requestObject.Settings.booksPaths[0].pathString)"
    
    Show-View $requestObject "index"
}
