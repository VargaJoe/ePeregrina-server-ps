
class RequestObject {
    [System.Net.HttpListenerContext]$HttpContext
    [System.Net.HttpListenerRequest]$HttpRequest
    [System.Uri]$RequestUrl
    [string]$LocalPath
    [string[]]$Paths
    [string]$Body
    [System.Collections.Specialized.NameValueCollection]$UrlVariables
    [string]$Controller

    RequestObject([System.Net.HttpListenerContext] $context) {
        $this.HttpContext = $context
        $this.HttpRequest = $context.Request
        $this.RequestUrl = $context.Request.Url
        $this.LocalPath = $this.RequestUrl.LocalPath
        $this.Paths = $this.LocalPath -Split '/'
        $this.Body = Get-JsonFromBody($this.HttpRequest)
        $this.UrlVariables = $this.HttpRequest.QueryString
        $this.Controller = $this.Paths[1]
    }
}


class SettingsObject {
    [string[]]$ComicsFolderPaths
    [string[]]$BooksFolderPaths

    SettingsObject() {
        $settingsFilePath = "./settings.json"
        $settings = Get-Content $settingsFilePath | ConvertFrom-Json
        $this.ComicsFolderPaths = $settings.ComicsFolderPaths
        $this.BooksFolderPaths = $settings.BooksFolderPaths
    }
}

function Get-JsonFromBody {
    param($HttpRequest)

    if($HttpRequest.HasEntityBody) {
        $Reader = New-Object System.IO.StreamReader($HttpRequest.InputStream)
        $json = $Reader.ReadToEnd() | ConvertFrom-Json 
        return $json
    }
}

function Show-HomeController {
    Write-Output "$($Global:Settings.ComicsFolderPaths)"
    Write-Output "$($Global:Settings.BooksFolderPaths)"
}