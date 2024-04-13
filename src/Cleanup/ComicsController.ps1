Add-Type -AssemblyName System.IO.Compression.FileSystem
function Show-ComicsController($requestObject) {
    Write-Output "paths: $($requestObject.Paths)"
    $folderIndex = [int]$($requestObject.Paths[2]) ?? 0;
    if ($requestObject.Paths.count -gt 3) {
        $paths = $requestObject.Paths[3..($requestObject.Paths.Count - 1)]

        # Check if the last part is "view" and remove it if it is
        if ($paths[-1] -eq "view") {
            $paths = $paths[0..($paths.Count - 2)]
        }

        $relServerPath = $paths -join '/'
    } else {
        $relServerPath = ""
    }
    $rootPath = $($requestObject.Settings.comicsPaths[$folderIndex].pathString)
    if (Test-Path -Path $rootPath) {
        $rootPath = Resolve-Path -Path $rootPath
    } 
    $absServerPath = "$rootPath/$relServerPath" -replace '/', '\'  
    write-output "WTF absServerPath: $absServerPath"
    if (Test-Path -LiteralPath "$absServerPath") {
        write-output "WTF absServerPath exists"
        $absServerPath = Resolve-Path -LiteralPath $absServerPath
    } else {
        write-output "WTF absServerPath does not exist"
    }
    
    Write-Output "index: $folderIndex"
    Write-Output "rel: $relServerPath"
    Write-Output "root: $rootPath"
    Write-Output "on server should be at: $absServerPath"


    Write-Output "1 $($requestObject.Controller)"
    Write-Output "2 $($requestObject.Category)"
    Write-Output "3 $($requestObject.FolderIndex)"
    Write-Output "4 $($requestObject.FolderPath)"
    Write-Output "5 $($requestObject.RelativePath)"
    Write-Output "6 $($requestObject.VirtualPath)"


    if (-not ($requestObject.Paths[-1] -eq "view")) {
        # category container
        # Create model
        $model = @{
            category = "books"
            items = Get-ChildItem -Path $absServerPath | ForEach-Object {
                $relUrlPath = "/" + $requestObject.Paths[1] + "/" + $folderIndex + $_.FullName.Replace($rootPath, "").Replace("\", "/")
                if (-not $_.PSIsContainer) { 
                    $relUrlPath += "/view"
                }
        
                # Create a custom object
                New-Object PSObject -Property @{
                    Name = $_.BaseName
                    Url = $relUrlPath
                }
            }
        }

        Show-View $requestObject "category" $model
    # } elseif ((($requestObject.Paths[5].EndsWith(".cbz")) -or ($requestObject.Paths[5].EndsWith(".zip"))) -and ($requestObject.Paths.length -eq 7)) {
    } elseif (($requestObject.Paths[-2].EndsWith(".cbz")) -or ($requestObject.Paths[-2].EndsWith(".zip"))) {
        # Handle .cbz file, it will be still an image list
        $cbzPath = $requestObject.Paths[1..($requestObject.Paths.Count - 2)] -Join "/"

        $zipFile = [System.IO.Compression.ZipFile]::OpenRead("$absServerPath")
        $zipFile.Entries | ForEach-Object {
            $_.FullName
            # $_.Name
        }
        $zipFile.Dispose()

        # Create model
        $model = @{
            category = "cbz"
            items = Get-ZipContents -Path "$absServerPath" | ForEach-Object {
                $relUrlPath = "/" + "$cbzPath" + "/" + "$($_.FullName -replace "/", "|")" + "/view"
        
                # Create a custom object
                New-Object PSObject -Property @{
                    Name = $_.FullName 
                    Url = $relUrlPath
                }
            }
        }

        Show-View $requestObject "category" $model    
    # } elseif ((($requestObject.Paths[5].EndsWith(".cbz")) -or ($requestObject.Paths[5].EndsWith(".zip"))) -and ($requestObject.Paths.length -gt 7)) {
    } elseif (($requestObject.Paths[-3].EndsWith(".cbz")) -or ($requestObject.Paths[-3].EndsWith(".zip"))) {
        # Handle .cbz file, it will be still an image list        
        $cbzPath = $requestObject.Paths[3..($requestObject.Paths.Count - 3)] -Join "/"
        # $fileName = $requestObject.Paths[6..($requestObject.Paths.Count - 2)] -Join "/"
        $fileName = "$($requestObject.Paths[-2])" -replace '\|', '/'
        write-output "cbzPath: $cbzPath"
        $absServerPath =  "$rootPath/$cbzPath"
        if (Test-Path -Path $absServerPath) {
            $absServerPath = Resolve-Path -Path $absServerPath
        } 
        write-output "absCbzServerPath: $absServerPath"
        write-output "fileName: $fileName"
        
        # Create model
        $model = @{
            category = "image"
            image = Get-ImageDataFromZip -ZipFilePath $absServerPath -ImageName $fileName            
        }

        Show-View $requestObject "image" $model

    } else { 
        # Create model
        $model = @{
            category = "image"
            "image" = Get-ImageData -ImagePath $absServerPath
        }

        Show-View $requestObject "image" $model
    }
}

function Get-ImageData {
    param (
        [string]$ImagePath
    )

    if (-not (Test-Path -LiteralPath $ImagePath)) {
        Write-Host "File not found: $ImagePath"
        return $null
    }

    $imageName = [System.IO.Path]::GetFileName($ImagePath)
    $imageContent = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ImagePath))

    $imageModel = [PSCustomObject]@{
        Name = $imageName
        Data = $imageContent
    }

    return $imageModel
}

function Get-ImageDataFromZip {
    param (
        [string]$ZipFilePath,
        [string]$ImageName
    )

    if (-not (Test-Path -LiteralPath $ZipFilePath)) {
        Write-Host "File not found: $ZipFilePath"
        return $null
    }
    
    $fileContent = Get-ZipFileContent -ZipFilePath $ZipFilePath -FileName $ImageName
    $imageContent = [System.Convert]::ToBase64String($fileContent)

    $imageModel = [PSCustomObject]@{
        Name = $ImageName
        Data = $imageContent
    }

    return $imageModel
}

function Get-ZipContents {
    param (
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "File not found: $Path"
        return
    }

    $zipFile = [System.IO.Compression.ZipFile]::OpenRead("$Path")
    $result = $zipFile.Entries 
    $zipFile.Dispose()
    return $result
}

function Get-ZipFileContent {
    param (
        [string]$ZipFilePath,
        [string]$FileName
    )

    if (-not (Test-Path -LiteralPath $ZipFilePath)) {
        Write-Host "File not found: $ZipFilePath"
        return
    }

    $zipFile = [System.IO.Compression.ZipFile]::OpenRead($ZipFilePath)
    $entry = $zipFile.GetEntry($FileName)

    if ($null -eq $entry) {
        Write-Host "File '$FileName' not found in the zip archive."
        return
    }

    $stream = $entry.Open()
    $memoryStream = New-Object System.IO.MemoryStream
    $stream.CopyTo($memoryStream)

    $memoryStream.Position = 0
    $bytes = $memoryStream.ToArray()

    $stream.Close()
    $memoryStream.Close()
    $zipFile.Dispose()

    return $bytes
}