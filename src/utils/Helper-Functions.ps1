function Get-JsonFromBody {
    param($HttpRequest)

    if($HttpRequest.HasEntityBody) {
        $Reader = New-Object System.IO.StreamReader($HttpRequest.InputStream)
        $json = $Reader.ReadToEnd() | ConvertFrom-Json 
        return $json
    }
}

function Show-Context {
    Write-Host "controller" $($requestObject.Controller)
    Write-Host "category" $($requestObject.Category)
    Write-Host "index" $($requestObject.FolderIndex)
    Write-Host "root" $($requestObject.FolderPath)
    Write-Host "rel" $($requestObject.RelativePath)
    Write-Host "virt" $($requestObject.VirtualPath)
    Write-Host "abs" $($requestObject.ContextPath)
}