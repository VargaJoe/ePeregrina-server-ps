function BinaryHandler($requestObject) {
    Write-Host "BinaryHandler"
    Show-Context
    # $fullPath = $(Join-Path $Global:RootPath $requestObject.Settings.webFolder $requestObject.LocalPath)
    $fullPath = $this.ContextPath
    Write-Output "fullpath: $($fullPath)"

    # "new response $fullpath" | Out-File -Append -FilePath "./log.txt"
    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    $response.ResponseType = "binary"
    # if (Test-Path $fullPath) { 
        $response.ResponseString = $Null
        $response.FilePath = Resolve-Path $fullPath
    # } else { 
    #     $response.ResponseString = $Null
    #     $response.FilePath = $Null
    #     $response.HttpResponse.StatusCode = 404
    # }
    
    $response.Respond()
    # "after response $fullpath" | Out-File -Append -FilePath "./log.txt"
}

function VirtualBinaryHandler($requestObject) {
    Write-Host "VirtualBinaryHandler"
    Show-Context
    # "new response $fullpath" | Out-File -Append -FilePath "./log.txt"
    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    $response.ResponseType = "binary"
    if ($requestObject.VirtualPath) { 
        $selectedFile = $requestObject.VirtualPath.TrimStart('/')
        $zipFile = $null
        $stream = $null

        try {
            $zipFile = [System.IO.Compression.ZipFile]::OpenRead($requestObject.ContextPath)
            $entry = $zipFile.GetEntry($selectedFile)
        
            if ($entry -eq $null) {
                throw "File '$selectedFile' not found in zip file."
            }
        
            $stream = $entry.Open()
            $reader = New-Object System.IO.StreamReader($stream)
            $response.ResponseString = $reader.ReadToEnd()
        } finally {
            $reader.Close()
            
            if ($null -ne $stream) {
                $stream.Close()
            }
        
            if ($null -ne $zipFile) {
                $zipFile.Dispose()
            }
        }
    } else { 
        $response.ResponseString = $Null
        $response.FilePath = $Null
        $response.HttpResponse.StatusCode = 404
        # $fullPath = Get-FilePath $requestObject -NotFound
    }
    
    $response.Respond()
    # "after response $fullpath" | Out-File -Append -FilePath "./log.txt"
}
