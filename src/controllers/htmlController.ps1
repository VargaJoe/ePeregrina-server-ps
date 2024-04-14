function Show-HtmlController($requestObject) {
    Write-Host "html controller"
    Show-Context

    $typeName = $this.ContextModelType + "ModelObject"
    Write-Host "type $typeName"
    if ([System.Management.Automation.PSTypeName]$typeName) {
        $pageModel = New-Object -TypeName $typeName -ArgumentList $requestObject
    }

    Show-View $requestObject "html" $pageModel.model
}
