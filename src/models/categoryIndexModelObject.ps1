class CategoryIndexModelObject {
    [PSCustomObject]$model = @{}

    CategoryIndexModelObject($requestObject) {
        $folderIndex = 0
        $allSharedFolder = $requestObject.Settings.PSObject.Properties | Where-Object { $_.Name -eq $requestObject.Category + "Paths" } | ForEach-Object {
            $_.Value | ForEach-Object {
                $FolderPathResolved = Resolve-Path -LiteralPath $_.pathString            
                Get-ChildItem -LiteralPath $_.pathString | ForEach-Object {
                    $relUrlPath = "/" + $requestObject.Category + "/" + $folderIndex + $_.FullName.Replace($FolderPathResolved, "").Replace("\", "/")
        
                    # Create a custom object
                    New-Object PSObject -Property @{
                        Name = $_.BaseName
                        Url = $relUrlPath
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