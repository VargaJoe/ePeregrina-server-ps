
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
            "binary" {
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

function Get-FilePath {
    param($requestObject)
    $fullPath = Join-Path $Global:RootPath "/themes/" $requestObject.Settings.Theme $requestObject.LocalPath
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
                & $functionName $requestObject
            }

            # Call the function dynamically based on the controller name
            # if physical file exists, show it
            $fullPath = Get-FilePath $requestObject
            Write-Output "fullpath: $($fullPath)"

            if (Test-Path $($fullPath)) {
                write-host yes
                BinaryHandler $requestObject
                break            
            }          
        }
    }
}

