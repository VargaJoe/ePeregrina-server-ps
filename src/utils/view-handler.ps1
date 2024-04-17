function Show-View {
    param(
        # [parameter(Mandatory = $true)]
        # [PelegrinaRequestObject]$requestObject,
        [parameter(Mandatory = $true)]
        [ResponseObject]$response,
        [parameter(Mandatory = $true)]
        [string]$viewName,
        [parameter(Mandatory = $false)]
        [Object]$model
    )
    # "new response $viewName" | Out-File -Append -FilePath "./log.txt"
    # $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    $response.ResponseType = "html"

    # Read the HTML content from the file
    $viewTemplate = (Get-Content -LiteralPath "./views/$viewName.pshtml" -Raw) #-Replace '"', '&quot;'
    # $evaluatedView = (Invoke-Expression "`"$viewTemplate`"") -Replace '&quot;', '"'    

    # Define a regular expression pattern to match PowerShell snippets within $( ... )
    $pattern = '<%\s*([\s\S]*?)\s*%>'

    # Use a regular expression match evaluator to evaluate PowerShell snippets
    # Create a regex object
    $regex = [regex]::new($pattern)

    # Initialize an array to store evaluated results
    $evaluatedSnippets = @()

    # Store the matches and their indices
    $matchIndices = @()
    foreach ($match in $regex.Matches($viewTemplate)) {
        $codeSnippet = $match.Groups[1].Value  # Access the matched code snippet
        Write-Host "matched: $codeSnippet"
        # Evaluate the code snippet
        $evaluatedSnippet = Invoke-Expression $codeSnippet
        if ($evaluatedSnippet -is [array]) {
            $evaluatedSnippet = $evaluatedSnippet -join " "
        }
        # Write-Host "evaluated: $evaluatedSnippet"
        $evaluatedSnippets += $evaluatedSnippet
        $matchIndices += $match.Index
    }

    # Replace the matched patterns with the evaluated results
    $evaluatedView = $regex.Replace($viewTemplate, {
        param($match)
        $index = [array]::IndexOf($matchIndices, $match.Index)
        $evaluatedSnippet = $evaluatedSnippets[$index]  # Use the match index to get the evaluated snippet
        return $evaluatedSnippet
    })

    # Evaluated HTML content goes to response
    $response.ResponseString = $evaluatedView
    $response.Respond()
    write-host done
}