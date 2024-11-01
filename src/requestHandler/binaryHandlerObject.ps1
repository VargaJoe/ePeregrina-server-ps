class BinaryHandler {
    [PSCustomObject]$response
    
    BinaryHandler($requestObject) {
        $typeName = "ResponseObject"
        if ([System.Management.Automation.PSTypeName]$typeName) {
            $this.response = New-Object -TypeName $typeName -ArgumentList $requestObject.HttpContext.Response
        }

        $this.response.ResponseType = "binary"
    }

    [void] GetPhysicalFile($requestObject) {
        Write-Host "BinaryHandler"
        Show-Context

        $fullPath = $requestObject.ContextPath
        Write-Host "fullpath: $($fullPath)"

        $this.response.ResponseString = $Null
        $this.response.FilePath = Resolve-Path -LiteralPath $fullPath
        
        $this.response.Respond()
    }

    [void] GetVirtualFile($requestObject) {
        Write-Host "VirtualBinaryHandler"
        Show-Context

        if ($requestObject.VirtualPath) { 
            $selectedFile = $requestObject.VirtualPath.TrimStart('/')
            $zipFile = $null
            $stream = $null
            $reader = $null
    
            try {
                $zipFile = [System.IO.Compression.ZipFile]::OpenRead($requestObject.ContextPath)
                $entry = $zipFile.GetEntry($selectedFile)
                
                if ($null -eq $entry) {
                    Write-Host "File '$selectedFile' not found in zip file."
                    return
                }
    
                $filename = $entry.Name
                $this.response.ContentType = Get-MimeType $filename
    
                $stream = $entry.Open()
                $reader = New-Object System.IO.BinaryReader($stream)
                $this.response.ResponseBytes = $reader.ReadBytes([int]$entry.Length)
            } finally {
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
            $this.response.ResponseBytes = $Null
            $this.response.ResponseString = $Null
            $this.response.FilePath = $Null
            $this.response.HttpResponse.StatusCode = 404
        }
        
        $this.response.Respond()
    }
    
}