function SampleController([ControllerRequestObject]$requestObject) {
    Write-Host "sample controller"
    Show-Context

    $model = @{
        category = "sample controller"
        controller = @{
            name = $requestObject.Controller
            action = $requestObject.Action
            parameters = $requestObject.Parameters -join ","
        } 
    }

    # Show-View $requestObject "controller" $model
    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    Show-View $response "controller" $model
}
