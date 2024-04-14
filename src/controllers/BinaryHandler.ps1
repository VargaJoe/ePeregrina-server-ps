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

            $filename = $entry.Name
            # $response.ContentType = [System.Web.MimeMapping]::GetMimeMapping($filename)
            $response.ContentType = Get-MimeType $filename

            # $stream = $entry.Open()
            # $memoryStream = New-Object System.IO.MemoryStream
            # $stream.CopyTo($memoryStream)
            # $memoryStream.Position = 0
            # $response.ResponseBytes = $memoryStream.ToArray()

            $stream = $entry.Open()
            $reader = New-Object System.IO.BinaryReader($stream)
            $response.ResponseBytes = $reader.ReadBytes([int]$entry.Length)
        } finally {
            if ($null -ne $memoryStream) {
                $memoryStream.Close()
            }

            if ($null -ne $reader) {
                $reader.Close()
            }
            
            if ($null -ne $stream) {
                $stream.Close()
            }
        
            if ($null -ne $zipFile) {
                $zipFile.Dispose()
            }
        }
    } else { 
        $response.ResponseBytes = $Null
        $response.ResponseString = $Null
        $response.FilePath = $Null
        $response.HttpResponse.StatusCode = 404
        # $fullPath = Get-FilePath $requestObject -NotFound
    }
    
    Write-Host bytes $response.ResponseBytes.Length
    $response.Respond()
    # "after response $fullpath" | Out-File -Append -FilePath "./log.txt"
}
