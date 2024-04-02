
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
                # $this.ContentType = "image/jpeg"
                $this.ContentType = "application/octet-stream"
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
            # The function name should be in the format "Show-{Controller}"
            $functionName = "Show-" + $requestObject.Controller + "Controller"
            if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                & $functionName $requestObject
            }

            # Call the function dynamically based on the controller name
            # if physical file exists, show it
            $fullPath = Join-Path $PSScriptRoot "/themes/" $requestObject.Settings.Theme $requestObject.LocalPath
            Write-Output "fullpath: $($fullPath)"

            if (Test-Path $($fullPath)) {
                write-host yes
                Show-FileFromPath $requestObject
                break            
            }          
        }
    }
}

function Show-HomeController($requestObject) {
    Write-Output "1 $($requestObject.Settings.theme)"
    Write-Output "3 $($requestObject.Settings.WebFolder)"
    Write-Output "4 $($requestObject.Settings.comicsPaths[0].pathString)"
    Write-Output "5 $($requestObject.Settings.booksPaths[0].pathString)"

    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    $response.ResponseType = "html"
    $response.FilePath = Resolve-Path "./index.html"
    $response.Respond()
}

function Show-FileFromPath($requestObject) {
    $fullPath = Join-Path $PSScriptRoot $requestObject.Settings.Theme $requestObject.LocalPath
    Write-Output "fullpath: $($fullPath)"

    $response = [ResponseObject]::new($requestObject.HttpContext.Response)
    $response.ResponseType = "img"
    $response.FilePath = Resolve-Path $fullPath
    $response.Respond()
}