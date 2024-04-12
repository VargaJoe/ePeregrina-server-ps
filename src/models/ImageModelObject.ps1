class ImageModelObject {
    [PSCustomObject]$model = @{}

    ImageModelObject($requestObject) {
        $this.model = @{
            type = "image"
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
}