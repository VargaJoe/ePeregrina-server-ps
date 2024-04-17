class ErrorRequestObject {
    [System.Net.HttpListenerContext]$HttpContext
    [System.Net.HttpListenerRequest]$HttpRequest
    [System.Uri]$RequestUrl
    [string]$LocalPath # url path without domain
    [string[]]$Paths
    [string]$Body
    [System.Collections.Specialized.NameValueCollection]$UrlVariables
    [PSCustomObject]$Settings

    [string]$ContextPath
    [string]$ContextModelType
    [string]$RequestType
    
    ErrorRequestObject([System.Net.HttpListener] $listener) {
        $this.Initialize($listener.GetContext())
    }

    ErrorRequestObject([System.Net.HttpListenerContext]$context) {
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

        Write-Host "404 page - category not set"
        $this.RequestType = "Error"
        $this.ContextModelType = "Error404"
        return
    }

    RouteRequest() {
        if ($this.RequestType -eq "Error") {
            Write-Host "404 page"
            # Error page is handled by the ErrorController
            PageHandler($this)
            return
        }
    }
}

