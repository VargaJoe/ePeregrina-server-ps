function Show-ComicsController($requestObject) {
    Write-Output "$($requestObject.Settings.comicsPaths[0].pathString)"
    $rootPath = $($requestObject.Settings.comicsPaths[0].pathString)
    
    $items = Get-ChildItem -Path $rootPath -Recurse

    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    $response.ResponseType = "html"
    # Read the index.html file into a string
    $HtmlString = Get-Content -Path "./index.html" -Raw

    # Create a list of items
    $Items = Get-ChildItem -Path $rootPath
    $LiElements = foreach ($Item in $Items) {
        "<li>$($Item.Name)</li>"
    }
    $LiString = $LiElements -join ""

    # Replace the <ul class="container"></ul> with the list of items
    $HtmlString = $HtmlString -replace '(<.*?class="container".*?>)\s*(</.*?>)', "`$1$LiString`$2"

    # Set the ResponseString to the modified HTML string
    $response.ResponseString = $HtmlString
    $response.Respond()
}
