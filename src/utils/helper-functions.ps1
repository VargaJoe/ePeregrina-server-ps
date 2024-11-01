function Get-JsonFromBody {
    param($HttpRequest)

    if($HttpRequest.HasEntityBody) {
        $Reader = New-Object System.IO.StreamReader($HttpRequest.InputStream)
        $json = $Reader.ReadToEnd() | ConvertFrom-Json 
        return $json
    }
}

function Show-Context {
    Write-Host "controller" $($requestObject.Controller)
    Write-Host "category" $($requestObject.Category)
    Write-Host "index" $($requestObject.FolderIndex)
    Write-Host "root" $($requestObject.FolderPath)
    Write-Host "rel" $($requestObject.RelativePath)
    Write-Host "virt" $($requestObject.VirtualPath)
    Write-Host "abs" $($requestObject.ContextPath)
    Write-Host "action" $($requestObject.Action)
}

function Get-MimeType {
    param (
        [Parameter(Mandatory=$true)]
        [string] $filename
    )

    $extension = [System.IO.Path]::GetExtension($filename).ToLower()

    $mimeTypes = @{
        '.txt'  = 'text/plain'
        '.pdf'  = 'application/pdf'
        '.doc'  = 'application/msword'
        '.docx' = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        '.xls'  = 'application/vnd.ms-excel'
        '.xlsx' = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        '.jpg'  = 'image/jpeg'
        '.png'  = 'image/png'
        '.gif'  = 'image/gif'
        '.zip'  = 'application/zip'
        # Add more mappings as needed
    }

    if ($mimeTypes.ContainsKey($extension)) {
        return $mimeTypes[$extension]
    } else {
        return 'application/octet-stream'  # Default MIME type
    }
}

function BinaryHandler($requestObject) {
    $binary = [BinaryHandler]::new($this)
    $binary.GetPhysicalFile($requestObject)
}

function VirtualBinaryHandler($requestObject) {
    $binary = [BinaryHandler]::new($this)
    $binary.GetVirtualFile($this)
}

function PageHandler($requestObject) {
    Show-Context
    $typeName = $this.ContextModelType + $this.VirtualModelType + "ModelObject"
    Write-Host "type $typeName"
    if ([System.Management.Automation.PSTypeName]$typeName) {
        $pageModel = New-Object -TypeName $typeName -ArgumentList $requestObject
    }
    Write-Host "model type" $pageModel.model.type
    if ($null -eq $pageModel -or $null -eq $pageModel.model -or $pageModel.model.type -eq "error") {
        Write-Host "Model not found or error occured."
        return
    }

    if ($pageModel.model.pageTemplate) {
        $pageTemplate = $pageModel.model.pageTemplate
    } else {
        $pageTemplate = ($this.VirtualModelType) ? $this.VirtualModelType : $this.ContextModelType
    }
    
    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    Show-View $response $pageTemplate $pageModel.model
}

function ActionHandler($requestObject) {
    Show-Context
    $typeName = $this.ContextModelType + $this.VirtualModelType + $this.Action + "ModelObject"
    Write-Host "action type $typeName"
    if ([System.Management.Automation.PSTypeName]$typeName) {
        # $actionModel = New-Object -TypeName $typeName -ArgumentList $requestObject
        # $actionModel = [CbzCoverModelObject]::new($this)
        # $actionModel = [System.Activator]::CreateInstance($type, @($this))
        try {
            $actionModel = New-Object -TypeName $typeName -ArgumentList $requestObject
        } catch {
            Write-Host "Error: $_"
            return
        }

    }
    # Write-Host "action model type" $actionModel.model.type
    # if ($null -eq $actionModel -or $null -eq $actionModel.model -or $actionModel.model.type -eq "error") {
    #     Write-Host "Model not found or error occured."
    #     return
    # }

    $actionModel.GetResponse($this)
}
