class CategoryFolderModelObject {
    [PSCustomObject]$model = @{}

    CategoryFolderModelObject($requestObject) {
        $this.model = @{
            type = "list"
            items = Get-ChildItem -LiteralPath $requestObject.ContextPath | ForEach-Object {
                $relUrlPath = "/" + $requestObject.Category + "/" + $requestObject.FolderIndex + $_.FullName.Replace($requestObject.FolderPathResolved, "").Replace("\", "/")
    
        
                # Create a custom object
                New-Object PSObject -Property @{
                    Name = $_.BaseName
                    Url = $relUrlPath
                }
            }
        }
    }
}