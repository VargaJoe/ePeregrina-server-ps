function Show-HomeController($requestObject) {
    Write-Output "1 $($requestObject.Settings.theme)"
    Write-Output "3 $($requestObject.Settings.WebFolder)"
    Write-Output "4 $($requestObject.Settings.comicsPaths[0].pathString)"
    Write-Output "5 $($requestObject.Settings.booksPaths[0].pathString)"
    
    Show-View $requestObject "index"
}

function Show-View($requestObject, $viewName) {
    $response = [ResponseObject]::new($requestObject.HttpContext.Response)    
    $response.ResponseType = "html"
    Write-Output "66 $"

    # Read the HTML content from the file
    $viewTemplate = (Get-Content -Path "./views/$viewName.pshtml" -Raw) #-Replace '"', '&quot;'
    # $evaluatedView = (Invoke-Expression "`"$viewTemplate`"") -Replace '&quot;', '"'    

    # Define a regular expression pattern to match PowerShell snippets within $( ... )
    $pattern = '\$\((.*?)\)'

    # Use a regular expression match evaluator to evaluate PowerShell snippets
    $evaluatedView = [regex]::Replace($viewTemplate, $pattern, {
        param($match)
        # Evaluate the PowerShell snippet
        $result = Invoke-Expression $match.Groups[1].Value
        # Return the evaluated result
        return $result
    })

    # Evaluated HTML content goes to response
    $response.ResponseString = $evaluatedView
    $response.Respond()    
}