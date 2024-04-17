class StaticRequestObject {
    [System.Net.HttpListenerContext]$HttpContext
    [System.Net.HttpListenerRequest]$HttpRequest
    [System.Uri]$RequestUrl
    [string]$LocalPath # url path without domain
    [string[]]$Paths
    [string]$Body
    [System.Collections.Specialized.NameValueCollection]$UrlVariables
    [PSCustomObject]$Settings

    [string]$ContextPath
    [string]$RequestType
    
    StaticRequestObject([System.Net.HttpListener] $listener) {
        $this.Initialize($listener.GetContext())
    }

    StaticRequestObject([System.Net.HttpListenerContext]$context) {
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

        $this.RequestType = ""

        Write-Host "url" $this.RequestUrl
        Write-Host "referrer" $this.HttpRequest.Headers["Referer"]
        Write-Host "accept" $this.HttpRequest.Headers["Accept"]
        Write-Host "user agent" $this.HttpRequest.UserAgent

        # webroot should be global from start script
        $webRootPath = ($this.Settings.webFolder) -replace "../", "/" -replace "./", "/" -replace "//", "/"
        if ($webRootPath.startswith("/")) {
            $webRootPath = $Global:RootPath + $webRootPath
            if (Test-Path -LiteralPath $webRootPath) {
                $webRootPath = Resolve-Path -LiteralPath $webRootPath
            } else {
                write-host "webRootPath not found: $webRootPath"
                exit
            }
        }
        
        $testFilePath = Join-Path -Path $webRootPath.Path -ChildPath $this.LocalPath
        if (Test-Path -LiteralPath $testFilePath -PathType Leaf) {
            # File page
            Write-Host "File resource" $testFilePath
            $this.RequestType = "File"
            # $this.Controller = "File"
            # $this.Action = "Stream"
            $this.ContextPath = Resolve-Path -LiteralPath $testFilePath
            return
        }
    }

    RouteRequest() {
        # /favicon.ico
        # /styles/style.css
        if ($this.RequestType -eq "File") {
            Write-Host "File resource"
            # If file exists on path file mode is handled by the binary handler
            BinaryHandler $this
            return
        }
    }
}

