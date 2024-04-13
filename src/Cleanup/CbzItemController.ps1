function Show-CbzItemController($requestObject) {
    Write-Host "1 $($requestObject.Controller)"
    Write-Host "2 $($requestObject.Category)"
    Write-Host "index $($requestObject.FolderIndex)"
    Write-Host "root $($requestObject.FolderPath)"
    Write-Host "rel $($requestObject.RelativePath)"
    Write-Host "6 $($requestObject.VirtualPath)"
    Write-Host "abs $($requestObject.ContextPath)"

    $selectedImage = $requestObject.VirtualPath.TrimStart('/')
    $imgObj = Get-ImageDataWithPagerFromZip -ZipFilePath $requestObject.ContextPath -ImageName $selectedImage
    Write-Host "YNumber of entries: $($imgObj.ToC.Count)"

    # write host toc type 
    Write-Host "toc type" ($imgObj.ToC.GetType().Name)

    $currentIndex = Get-PagerIndex -ImageName $selectedImage -pagerItems $imgObj.ToC
    $prevIndex = $currentIndex - 1
    $nextIndex = $currentIndex + 1
    Write-Host $prevIndex $imgObj.ToC[$prevIndex]
    Write-Host $nextIndex $imgObj.ToC[$nextIndex]
    Write-Host "Length: $($imgObj.Data.Length)"
    # Create model
    $model = @{
        category = "image"
        pager = @{
            prev = $prevIndex -ge 0 ? $imgObj.ToC[$prevIndex] : $null
            next = $nextIndex -lt $imgObj.ToC.Count ? $imgObj.ToC[$nextIndex] : $null
        }        
        image = @{
            Name = $selectedImage
            Data = $imgObj.Data
        }       
    }

    Show-View $requestObject "image" $model 
}

function Get-PagerIndex {
    param (
        [string]$ImageName,
        [object[]]$pagerItems        
    )
    $currentPageIndex = -1

    # Find the current page index
    Write-Host "ImageName: $ImageName"
    Write-Host "PagerItems: $($pagerItems)"
    foreach ($item in $pagerItems) {
        Write-Host "Item: $($item.Name)"
        $currentPageIndex = $currentPageIndex + 1
        if ($item.Name -eq $ImageName) {
            # $currentPageIndex = $pagerItems.IndexOf($item)
            write-host "FOUND" $currentPageIndex $($item.Name) 
            break
        } else {
            write-host "NOT FOUND" $currentPageIndex $($item.Name) 
        }
    }
    Write-Host "Current Page Index: $currentPageIndex"

    return $currentPageIndex
}

function Get-ImageDataFromZip {
    param (
        [string]$ZipFilePath,
        [string]$ImageName
    )

    $fileContent = Get-ZipFileContent -ZipFilePath $ZipFilePath -FileName $ImageName
    $imageContent = [System.Convert]::ToBase64String($fileContent)

    $imageModel = [PSCustomObject]@{
        Name = $ImageName
        Data = $imageContent
    }

    return $imageModel
}

function Get-ImageDataWithPagerFromZip {
    param (
        [string]$ZipFilePath,
        [string]$ImageName
    )

    $zipObj = Get-ZipFileContentWithPager -ZipFilePath $ZipFilePath -FileName $ImageName
    $imageContent = [System.Convert]::ToBase64String($zipObj.bytes)
    $imageModel = [PSCustomObject]@{
        Name = $ImageName
        ToC  = $zipObj.toc
        Data = $imageContent
    }

    return $imageModel
}

function Get-ZipFileContent {
    param (
        [string]$ZipFilePath,
        [string]$FileName
    )

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

function Get-ZipFileContentWithPager {
    param (
        [string]$ZipFilePath,
        [string]$FileName
    )
    
    $zipFile = [System.IO.Compression.ZipFile]::OpenRead($ZipFilePath)
    $toc = $zipFile.Entries | ForEach-Object {
        $relUrlPath = $requestObject.ReducedLocalPath + "/" + "$($_.FullName -replace "/", "|")"
        
        # Create a custom object
        New-Object PSObject -Property @{
            Name = $_.FullName 
            Url  = $relUrlPath
        }
    }   
    
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

    return @{ 
        toc = $toc
        bytes = $bytes
    }
}