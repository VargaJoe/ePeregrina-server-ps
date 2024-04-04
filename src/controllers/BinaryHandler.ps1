function BinaryHandler($requestObject) {
    $fullPath = $fullPath = Get-FilePath $requestObject
    Write-Output "fullpath: $($fullPath)"

    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    $response.ResponseType = "binary"
    if (Test-Path $fullPath) { 
        $response.ResponseString = $Null
        $response.FilePath = Resolve-Path $fullPath
    } else { 
        $response.ResponseString = $Null
        $response.FilePath = $Null
        $response.HttpResponse.StatusCode = 404
        # $fullPath = Get-FilePath $requestObject -NotFound
    }
    
    $response.Respond()
}