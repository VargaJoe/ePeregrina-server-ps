function Show-ComicsController($requestObject) {
    Write-Output "paths: $($requestObject.Paths)"
    $folderIndex = [int]$($requestObject.Paths[2]) ?? 0;
    $relServerPath = ($requestObject.Paths[3..($requestObject.Paths.Count - 1)]) -join '/'
    $rootPath = $($requestObject.Settings.comicsPaths[$folderIndex].pathString)
    $absServerPath = "$rootPath/$relServerPath"
    
    Write-Output "index: $folderIndex"
    Write-Output "rel: $relFilePath"
    Write-Output "root: $rootPath"
    Write-Output "on server should be at: $absServerPath"
    
    $model = Get-ChildItem -Path $absServerPath #-Recurse
    Show-View $requestObject "category" $model
}
