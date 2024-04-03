function BinaryHandler($requestObject) {
    $fullPath = $fullPath = Get-FilePath $requestObject
    Write-Output "fullpath: $($fullPath)"

    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    $response.ResponseType = "binary"
    $response.FilePath = Resolve-Path $fullPath
    $response.Respond()
}