class ControllerRequestObject {
    [System.Net.HttpListenerContext]$HttpContext
    [System.Net.HttpListenerRequest]$HttpRequest
    [System.Uri]$RequestUrl
    [string]$LocalPath # url path without domain
    [string[]]$Paths
    [string]$Body
    [System.Collections.Specialized.NameValueCollection]$UrlVariables
    [PSCustomObject]$Settings

    # Controller name
    [string]$Controller
    [string]$Action
    [string[]]$Parameters
    [string]$ControllerFunction
    [string]$RequestType
    
    ControllerRequestObject([System.Net.HttpListener] $listener) {
        $this.Initialize($listener.GetContext())
    }

    ControllerRequestObject([System.Net.HttpListenerContext]$context) {
        $this.Initialize($context)
    }

    [void]Initialize([System.Net.HttpListenerContext]$context) {        
        $this.HttpContext = $context
        $this.HttpRequest = $this.HttpContext.Request
        $this.RequestUrl = $this.HttpContext.Request.Url
        $this.LocalPath = ($this.RequestUrl.LocalPath -replace "//", "/") -replace "/$", ""
        $this.Paths = $this.LocalPath -Split '/'
        $this.Body = Get-JsonFromBody($this.HttpRequest)
        $this.UrlVariables = $this.HttpRequest.QueryString

        $settingsFilePath = "./settings.json"
        $this.Settings = Get-Content $settingsFilePath | ConvertFrom-Json

        # https://domain/category/folderindex/relativepath/virtualpath
        # default
        $this.Controller = ""
        $this.ControllerFunction = ""
        $this.RequestType = ""
        $this.Action = ""
        $this.Parameters = @()

        Write-Host "url" $this.RequestUrl
        Write-Host "referrer" $this.HttpRequest.Headers["Referer"]
        Write-Host "accept" $this.HttpRequest.Headers["Accept"]
        Write-Host "user agent" $this.HttpRequest.UserAgent

        if ($this.Paths.Length -lt 2) {
            return
        }

        # Check if controller exists in the format "Show-{Controller}"
        $this.Controller = $this.Paths[1]
        $functionName = $this.Controller + "Controller"
        if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
            return
        }

        $this.ControllerFunction = $functionName
        $this.RequestType = "Controller"

        if ($this.Paths.Length -gt 2) {
            $this.Action = $this.Paths[2]
        }

        if ($this.Paths.Length -gt 3) {
            $this.Parameters = $this.Paths[3..($this.Paths.Length - 1)]            
        }

    }

    RouteRequest() {
        # /controller/action/parameter/s
        if ($this.RequestType -eq "Controller") {
            # Controller mode is handled by the controller function via naming convention
            & $this.ControllerFunction $this
            return
        }
    }
}

