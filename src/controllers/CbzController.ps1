function Show-CbzController($requestObject) {
     $zipFile = [System.IO.Compression.ZipFile]::OpenRead($requestObject.ContextPath)
     $zipFile.Entries | ForEach-Object {
         $_.FullName
         # $_.Name
     }
     $zipFile.Dispose()

     # Create model
     $model = @{
         category = "cbz"
         items = Get-ZipContents -Path $requestObject.ContextPath | ForEach-Object {
             $relUrlPath = $requestObject.LocalPath + "/" + "$($_.FullName -replace "/", "|")"
     
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
    $result = $zipFile.Entries 
    $zipFile.Dispose()
    return $result
}