function Show-CbzController($requestObject) {
    Write-Host "cbz controller"
    Show-Context

     # Create model
     $model = @{
         category = "cbz"
         items = Get-ZipContents -Path $requestObject.ContextPath | ForEach-Object {
             $relUrlPath = $requestObject.LocalPath + "/" + "$($_.FullName)"
     
             # Create a custom object
             New-Object PSObject -Property @{
                 Name = $_.FullName 
                 Url = $relUrlPath
             }
         }
     }

     Show-View $requestObject "category" $model   
}

function Get-ZipContents {
    param (
        [string]$Path
    )

    $zipFile = [System.IO.Compression.ZipFile]::OpenRead("$Path")
    $result = $zipFile.Entries | Where-Object { $_.FullName -notlike "__MACOSX*" -and $_.FullName -notlike "*/" }
    $zipFile.Dispose()
    return $result
}