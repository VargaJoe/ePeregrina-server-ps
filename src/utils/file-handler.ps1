function Get-FilePath {
    param($requestObject)
    $fullPath = $(Join-Path $Global:RootPath $requestObject.Settings.webFolder $requestObject.LocalPath)
    # if (Test-Path $fullPath) {
    # if (Test-Path $(Join-Path $Global:RootPath $requestObject.Settings.webFolder $requestObject.LocalPath)) {
    #     $fullPath = Resolve-Path $(Join-Path $Global:RootPath $requestObject.Settings.webFolder $requestObject.LocalPath)
    # }    
    return $fullPath
}


