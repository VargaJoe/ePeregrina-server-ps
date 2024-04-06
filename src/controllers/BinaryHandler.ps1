function BinaryHandler($requestObject) {
    $fullPath = Get-FilePath $requestObject
    Write-Output "fullpath: $($fullPath)"

    "new response $fullpath" | Out-File -Append -FilePath "./log.txt"
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
    "after response $fullpath" | Out-File -Append -FilePath "./log.txt"
}