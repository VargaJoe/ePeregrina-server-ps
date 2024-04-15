function Show-CategoryIndexController($requestObject) {
    Write-Host "category index controller"
    Show-Context

    # category container
    # Create model
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
        
    $model = @{
        category = $requestObject.Category
        items = $allSharedFolder
    }
    
    Show-View $requestObject "category" $model
}
