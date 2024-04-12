function Show-ImageController($requestObject) {
    Write-Host "1 $($requestObject.Controller)"
    Write-Host "2 $($requestObject.Category)"
    Write-Host "index $($requestObject.FolderIndex)"
    Write-Host "root $($requestObject.FolderPath)"
    Write-Host "rel $($requestObject.RelativePath)"
    Write-Host "6 $($requestObject.VirtualPath)"
    Write-Host "abs $($requestObject.ContextPath)"

    $typeName = $this.ContextModelType + "ModelObject"
    Write-Host "type $typeName"
    if ([System.Management.Automation.PSTypeName]$typeName) {
        $pageModel = New-Object -TypeName $typeName -ArgumentList $requestObject
    }

    Show-View $requestObject "image" $pageModel.model
}
