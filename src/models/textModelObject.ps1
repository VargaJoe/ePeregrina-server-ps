class TextModelObject {
    [PSCustomObject]$model = @{}

    TextModelObject($requestObject) {
        $this.model = @{
            category = "text"
            textFile = $this.GetFileData($requestObject.ContextPath)
        }
    }

    [PSCustomObject] GetFileData([string]$FilePath) {
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        $fileContent = Get-Content -LiteralPath $FilePath -Raw 
        if ($fileContent.Contains("�")) {
            # convert to latin-2
            $fileContent = Get-Content -LiteralPath $FilePath -Raw -Encoding ISO-8859-2
        }
        
        $fileContent = $fileContent -replace "`r`n", "<br/>"
        
        $fileModel = [PSCustomObject]@{
            Name = $fileName
            Data = $fileContent
        }
    
        return $fileModel
    }
    
}