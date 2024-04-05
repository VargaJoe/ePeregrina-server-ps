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