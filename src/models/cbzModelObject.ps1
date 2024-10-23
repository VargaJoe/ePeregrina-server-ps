class CbzModelObject {
    [PSCustomObject]$model = @{}

    CbzModelObject($requestObject) {
        $this.model = @{
            type = "list"
            category = "cbz"
            
            items = $this.GetZipContents($requestObject.ContextPath) 
            # | ForEach-Object {
            #     $relUrlPath = $requestObject.LocalPath + "/" + "$($_.FullName)"
        
            #     # Create a custom object
            #     New-Object PSObject -Property @{
            #         Name = $_.FullName 
            #         Url = $relUrlPath
            #     }
            # }
        }
    }

    [PSCustomObject]GetZipContents([string]$Path) {
        write-host "!!!!Request Object: $($Path)"
        $zipFile = [System.IO.Compression.ZipFile]::OpenRead("$Path")        
        $firstItem = $true;
        $result = $zipFile.Entries | Where-Object { $_.FullName -notlike "__MACOSX*" -and $_.FullName -notlike "*/" } | ForEach-Object {
            $entry = $_
            $relUrlPath = $requestObject.LocalPath + "/" + "$($entry.FullName)"
            
            # Get cover image
            if ($firstItem) {
                $stream = $entry.Open()
                $memoryStream = New-Object System.IO.MemoryStream
                $stream.CopyTo($memoryStream)

                # $memoryStream.Position = 0
                # $bytes = $memoryStream.ToArray()

                # test image start
                $thumbnailWidth = 120
                $thumbnailHeight = 120
                $originalImage = [System.Drawing.Image]::FromStream($memoryStream)
                $thumbnailImage = $originalImage.GetThumbnailImage($thumbnailWidth, $thumbnailHeight, $null, [IntPtr]::Zero)
                $thumbnailStream = New-Object System.IO.MemoryStream
                $thumbnailImage.Save($thumbnailStream, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                $bytes = $thumbnailStream.ToArray()
                
                $contextFileName = [System.IO.Path]::GetFileNameWithoutExtension($requestObject.ContextPath)
                $thumbnailContainerPath = "$($requestObject.WebFolderPath)\covers\$($contextFileName).jpg"
                write-host "!!!!Thumbnail Container Path: $($thumbnailContainerPath)"
                $thumbnailImage.Save($thumbnailContainerPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

                # $thumbnailStream.Close()
                # $thumbnailImage.Dispose()
                # $originalImage.Dispose()
                # $imageStream.Close()
                
                # test image end

                $stream.Close()
                $memoryStream.Close()
                
                $firstItem = $false
            }

            if ($bytes) {
                $image = [System.Convert]::ToBase64String($bytes)                

                # # Create a thumbnail image
                # $thumbnailWidth = 200
                # $thumbnailHeight = 200
                # $thumbnailContainerPath = $requestObject.WebFolderPath + "\thumbnails\thumbnail.jpg" #+ $requestObject.LocalPath + "\" + $entry.FullName + ".jpg"

                # # Convert base64 string back to image
                # $imageBytes = [System.Convert]::FromBase64String($image)
                # $imageStream = New-Object System.IO.MemoryStream
                # $imageStream.Write($imageBytes, 0, $imageBytes.Length)
                # $imageStream.Position = 0

                # $originalImage = [System.Drawing.Image]::FromStream($imageStream)
                # $thumbnailImage = $originalImage.GetThumbnailImage($thumbnailWidth, $thumbnailHeight, $null, [IntPtr]::Zero)

                # # Save the thumbnail image
                # $thumbnailImage.Save($thumbnailContainerPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

                # # Clean up
                # $originalImage.Dispose()
                # $thumbnailImage.Dispose()
                # $imageStream.Close()
            } else {
                $image = $null
            }

            # Create a custom object
            New-Object PSObject -Property @{
                Name = $_.FullName 
                Url  = $relUrlPath
                Image = $image
            }
            $bytes = $null
        }
        $zipFile.Dispose()
        return $result
    }
}
