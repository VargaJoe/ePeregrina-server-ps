class ImageModelObject {
    [PSCustomObject]$model = @{}

    ImageModelObject($requestObject) {
        $this.model = @{
            type = "image"
            pager = $this.GetPager($requestObject)
            image = $this.GetImageData($requestObject.ContextPath)
        }        
    }

    [PSCustomObject]GetImageData($imagePath) {
        $imageName = [System.IO.Path]::GetFileName($ImagePath)
        $imageContent = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ImagePath))
    
        $imageModel = [PSCustomObject]@{
            Name = $imageName
            Data = $imageContent
        }
    
        return $imageModel
    }

    [PSCustomObject]GetPager($requestObject){
        $ImagePath = $requestObject.ContextPath 
        $relativeContainerPath = (Split-Path -Path $requestObject.LocalPath -Parent) -replace "\\", "/"

        $containerPath = [System.IO.Path]::GetDirectoryName($ImagePath)
        $imageName = [System.IO.Path]::GetFileName($imagePath)
        $pagerItems = Get-ChildItem -Path $containerPath | ForEach-Object {
            $relUrlPath = $relativeContainerPath + "/" + "$($_.Name)"
            
            New-Object PSObject -Property @{
                Name = $_.Name 
                Url  = $relUrlPath
            }
        }


        $currentIndex = -1
        foreach ($item in $pagerItems) {
            $currentIndex = $currentIndex + 1
            if ($item.Name -eq $imageName) {
                break
            } 
        }
        $prevIndex = $currentIndex - 1
        $nextIndex = $currentIndex + 1
        $pager = @{
            prev = $prevIndex -ge 0 ? $pagerItems[$prevIndex] : $null
            next = $nextIndex -lt $pagerItems.Count ? $pagerItems[$nextIndex] : $null
        }

        return $pager
    }
}