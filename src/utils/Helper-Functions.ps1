
class RequestObject {
    [System.Net.HttpListener]$HttpListener
    [System.Net.HttpListenerContext]$HttpContext
    [System.Net.HttpListenerRequest]$HttpRequest
    [System.Uri]$RequestUrl
    [string]$LocalPath
    [string[]]$Paths
    [string]$Body
    [System.Collections.Specialized.NameValueCollection]$UrlVariables
    [string]$Controller
    [PSCustomObject]$Settings

    RequestObject([System.Net.HttpListener] $listener) {
        $this.HttpListener = $listener
        $this.HttpContext = $listener.GetContext()
        $this.HttpRequest = $this.HttpContext.Request
        $this.RequestUrl = $this.HttpContext.Request.Url
        $this.LocalPath = $this.RequestUrl.LocalPath
        $this.Paths = $this.LocalPath -Split '/'
        $this.Body = Get-JsonFromBody($this.HttpRequest)
        $this.UrlVariables = $this.HttpRequest.QueryString
        $this.Controller = $this.Paths[1]

        $settingsFilePath = "./settings.json"
        $this.Settings = Get-Content $settingsFilePath | ConvertFrom-Json
    }
}

class ResponseObject {
    [System.Net.HttpListenerResponse]$HttpResponse
    [string]$FilePath
    [string]$ResponseString
    [string]$ResponseType
    [string]$ContentType

    ResponseObject([System.Net.HttpListenerResponse] $response) {
        $this.HttpResponse = $response
        $this.HttpResponse.Headers.Add("Access-Control-Allow-Origin", "*")
        $this.HttpResponse.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        $this.HttpResponse.StatusCode = 200
    }

    [void] Respond() {
        $ResponseBuffer = @()
        switch ($this.ResponseType) {
            "json" {
                $this.ContentType = "application/json"
            }
            "html" {
                $this.ContentType = "text/html"
            }
            "binary" {
                $this.ContentType = "application/octet-stream"
            }
            Default {}
        }

        try {
            if ($this.ResponseString -and $this.ResponseString.Length -gt 0) {
                $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($this.ResponseString)
            } elseif ($this.filepath) {
                $ResponseBuffer = [System.IO.File]::ReadAllBytes($this.FilePath)
            } else {
                $this.HttpResponse.StatusCode = 404
            }

            if ($ResponseBuffer.Length -gt 0) {
                $this.HttpResponse.ContentLength64 = $ResponseBuffer.Length
                $this.HttpResponse.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)                
            }
            $this.HttpResponse.Headers.Add("Content-Type", $this.ContentType)
        } catch {
            $this.HttpResponse.StatusCode = 500
        } finally {
            $this.HttpResponse.OutputStream?.Flush()
            $this.HttpResponse.Close()
            "close response" | Out-File -Append -FilePath "./log.txt"
        }
    }
}

function Get-FilePath {
    param($requestObject)
    $fullPath = $(Join-Path $Global:RootPath $requestObject.Settings.webFolder $requestObject.LocalPath)
    # if (Test-Path $fullPath) {
    # if (Test-Path $(Join-Path $Global:RootPath $requestObject.Settings.webFolder $requestObject.LocalPath)) {
    #     $fullPath = Resolve-Path $(Join-Path $Global:RootPath $requestObject.Settings.webFolder $requestObject.LocalPath)
    # }    
    return $fullPath
}
function Get-JsonFromBody {
    param($HttpRequest)

    if($HttpRequest.HasEntityBody) {
        $Reader = New-Object System.IO.StreamReader($HttpRequest.InputStream)
        $json = $Reader.ReadToEnd() | ConvertFrom-Json 
        return $json
    }
}

function RedirectRequest($requestObject, $newUrl) {
    $response = $requestObject.HttpContext.Response
    $response.StatusCode = 302
    $response.RedirectLocation = $newUrl
    $response.Close()
}

function RouteRequest($requestObject) {
    switch ($requestObject.Controller.ToLower()) {
        "shutdown" {
            Write-Host "`nListener shutting down..."
            $requestObject.HttpListener.Stop()
            exit
        }
        "restart" {
            Write-Host "`nListener shutting down..."
            $requestObject.HttpListener.Stop()
            
            Write-Host "`nListener starting..."
            $requestObject.HttpListener.Start()
            
            Write-Host "`nRedirect to root to prevent infinite loop..."
            $requestObject = [RequestObject]::new($HttpListener)
            RedirectRequest $requestObject "/"
        }
        "reload" {
            Write-Host "`nListener shutting down..."
            $requestObject.HttpListener.Stop()
            
            Write-Host "`nReloading script, so the listener will restart..."
            . ./Http-Listener.ps1
        }
        "" {
            Show-HomeController $requestObject
        }
        "index" {
            Show-HomeController $requestObject
        }
        default {
            # The function name should be in the format "Show-{Controller}"
            $functionName = "Show-" + $requestObject.Controller + "Controller"
            if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                # Call the function dynamically based on the controller name if exists
                & $functionName $requestObject
            } else {
                # If the controller does not exist, treat it as a binary request
                BinaryHandler $requestObject
            }     
        }
    }
}


function Show-View {
    param(
        [parameter(Mandatory=$true)]
        [RequestObject]$requestObject,
        [parameter(Mandatory=$true)]
        [string]$viewName,
        [parameter(Mandatory=$false)]
        [Object]$model
    )
    "new response $viewName" | Out-File -Append -FilePath "./log.txt"
    $response = [ResponseObject]::new($requestObject.HttpContext.Response)    
    $response.ResponseType = "html"

    # Read the HTML content from the file
    $viewTemplate = (Get-Content -Path "./views/$viewName.pshtml" -Raw) #-Replace '"', '&quot;'
    # $evaluatedView = (Invoke-Expression "`"$viewTemplate`"") -Replace '&quot;', '"'    

    # Define a regular expression pattern to match PowerShell snippets within $( ... )
    $pattern = '<%\s*([\s\S]*?)\s*%>'

    
    # $result = foreach ($item in $model) {
    #     $fileNameWithoutPath = $item.BaseName
    #     "<br/><br/><br/>" +
    #     "<a href='/comics/1/' class='rootlink'>$fileNameWithoutPath</a>"
    # }
    # write-host $result
    # Use a regular expression match evaluator to evaluate PowerShell snippets
    # Create a regex object
    $regex = [regex]::new($pattern)

    # Initialize an array to store evaluated results
$evaluatedSnippets = @()

# Store the matches and their indices
$matchIndices = @()
foreach ($match in $regex.Matches($viewTemplate)) {
    $codeSnippet = $match.Groups[1].Value  # Access the matched code snippet
    Write-Host "matched: $($match.Groups[1].Value)"
    # Evaluate the code snippet
    $evaluatedSnippet = Invoke-Expression $codeSnippet
    if ($evaluatedSnippet -is [array]) {
        $evaluatedSnippet = $evaluatedSnippet -join " "
    }
    Write-Host "evaluated: $evaluatedSnippet"
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
   

    # $evaluatedView = [regex]::Replace($viewTemplate, $pattern, {
    #     param($match)
    #     # Evaluate the PowerShell snippet
    #     $result = Invoke-Expression $match.Groups[1].Value
    #     # Return the evaluated result
    #     return $result
    # })
    write-host done

    # Evaluated HTML content goes to response
    $response.ResponseString = $evaluatedView
    $response.Respond()
    "after response $viewName" | Out-File -Append -FilePath "./log.txt"
}