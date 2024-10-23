class CategoryIndexModelObject {
    [PSCustomObject]$model = @{}

    CategoryIndexModelObject($requestObject) {
        $folderIndex = 0
        $allSharedFolder = $requestObject.Settings.PSObject.Properties | Where-Object { $_.Name -eq $requestObject.Category + "Paths" } | ForEach-Object {
            $_.Value | ForEach-Object {
                $FolderPathResolved = Resolve-Path -LiteralPath $_.pathString            
                Get-ChildItem -LiteralPath $_.pathString | ForEach-Object {
                    $relUrlPath = "/" + $requestObject.Category + "/" + $folderIndex + $_.FullName.Replace($FolderPathResolved, "").Replace("\", "/")
                    $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($relUrlPath)
                    $thumbnailContainerPath = "$($requestObject.WebFolderPath)\covers\$($contextFileName).jpg"
                    
                    $thumbnailBase64 = ""
                    if (Test-Path $thumbnailContainerPath) {
                        $image = [System.Drawing.Image]::FromFile($thumbnailContainerPath)
                        $imageStream = New-Object System.IO.MemoryStream
                        $image.Save($imageStream, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                        $imageStream.Position = 0
                        $imageBytes = New-Object byte[] $imageStream.Length
                        $imageStream.Read($imageBytes, 0, $imageStream.Length)
                        $thumbnailBase64 = [Convert]::ToBase64String($imageBytes)
                        $imageStream.Close()
                        $image.Dispose()                        
                    }
                    Write-Host "MIVAN????" $_.BaseName
                    # Create a custom object
                    New-Object PSObject -Property @{
                        Name = $_.BaseName
                        Url = $relUrlPath
                        Thumbnail = $thumbnailBase64
                    }
                }
                $folderIndex = $folderIndex + 1
            }
        } | Sort-Object Name
            
        $this.model = @{
            type = "list"
            category = $requestObject.Category
            items = $allSharedFolder
        }
    }
}