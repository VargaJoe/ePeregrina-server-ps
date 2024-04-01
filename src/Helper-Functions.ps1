
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
    }
}

class ResponseObject {
    [System.Net.HttpListenerResponse]$HttpResponse
    [string]$JsonData
    [string]$FilePath
    [string]$ResponseType
    [string]$ContentType

    ResponseObject([System.Net.HttpListenerResponse] $response) {
        $this.HttpResponse = $response
        $this.HttpResponse.Headers.Add("Access-Control-Allow-Origin", "*")
        $this.HttpResponse.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        $this.HttpResponse.StatusCode = 200
    }

    [void] Respond() {
        $ResponseBuffer = $null
        switch ($this.ResponseType) {
            "json" {
                $this.ContentType = "application/json"
                $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($this.JsonData)
            }
            "html" {
                $this.ContentType = "text/html"
                $ResponseBuffer = [System.IO.File]::ReadAllBytes($this.FilePath)
            }
            "img" {
                $this.ContentType = "image/jpeg"
                $ResponseBuffer = [System.IO.File]::ReadAllBytes($this.FilePath)
            }
            Default {}
        }
        $this.HttpResponse.ContentLength64 = $ResponseBuffer.Length
        $this.HttpResponse.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
        $this.HttpResponse.Headers.Add("Content-Type", $this.ContentType)
        $this.HttpResponse.Close()
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

function RouteRequest($requestObject) {
    switch ($requestObject.Controller.ToLower()) {
        "shutdown" {
            Write-Host "`nListener shutting down..."
            $requestObject.HttpListener.Stop()
            exit
        }
        "" {
            Show-HomeController $requestObject
        }
        "index" {
            Show-HomeController $requestObject
        }
        default {
            # Call the function dynamically based on the controller name
            # The function name should be in the format "Show-{Controller}"
            # $fullPath = Resolve-Path (Join-Path $PSScriptRoot $requestObject.LocalPath)
            $relPath = Join-Path $PSScriptRoot $requestObject.LocalPath
            # $fullPath = Resolve-Path (Join-Path $PSScriptRoot $requestObject.LocalPath)
            Write-Output "relpath: $($relPath)"
            Write-Output "fullpath: $($fullPath)"

            if (Test-Path $($relPath)) {
                write-host yes
                break            
            } else {
                write-host no
                break   
            }


            # $functionName = "Show-" + $requestObject.Controller
            # if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            #     & $functionName
            # } else {
            #     Write-Host "No function found for controller: $requestObject.Controller"
            # }
        }
    }
}

function Show-HomeController($requestObject) {
    Write-Output "$($Global:Settings.ComicsFolderPaths)"
    Write-Output "$($Global:Settings.BooksFolderPaths)"

    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    $response.ResponseType = "html"
    $response.FilePath = Resolve-Path "./index.html"
    $response.Respond()
}