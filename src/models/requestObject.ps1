class RequestObject {
    [System.Net.HttpListener]$HttpListener
    [System.Net.HttpListenerContext]$HttpContext
    [System.Net.HttpListenerRequest]$HttpRequest
    [System.Uri]$RequestUrl
    [string]$LocalPath
    [string[]]$Paths
    [string]$Body
    [System.Collections.Specialized.NameValueCollection]$UrlVariables
    [PSCustomObject]$Settings

    # Controller name
    [string]$Controller
    [string]$ControllerFunction
    # Category by settings
    [string]$Category
    # index of local server path in settings
    [string]$FolderIndex
    # local server path in settings
    [string]$FolderPath
    [string]$FolderPathResolved
    # url path
    [string]$RelativePath
    [bool]$IsContainer
    # index of item in folder
    [string]$ItemIndex
    # path to the file or folder on the webserver
    [string]$ContainerPath
    # parent path to the file or folder on the webserver
    [string]$ContextPath
    # path to the file or folder on webserver or under the container
    [string]$VirtualPath
    # action to be performed
    [string]$Action

    [string]$RequestType
    
    RequestObject([System.Net.HttpListener] $listener) {
        $this.HttpListener = $listener
        $this.HttpContext = $listener.GetContext()
        $this.HttpRequest = $this.HttpContext.Request
        $this.RequestUrl = $this.HttpContext.Request.Url
        $this.LocalPath = ($this.RequestUrl.LocalPath -replace "//", "/") -replace "/$", ""
        $this.Paths = $this.LocalPath -Split '/'
        $this.Body = Get-JsonFromBody($this.HttpRequest)
        $this.UrlVariables = $this.HttpRequest.QueryString

        $settingsFilePath = "./settings.json"
        $this.Settings = Get-Content $settingsFilePath | ConvertFrom-Json

        # default
        $this.Controller = ""
        $this.ControllerFunction = ""
        $this.Category = ""
        $this.FolderIndex = 0
        $this.FolderPath = ""
        $this.FolderPathResolved = ""
        $this.RelativePath = ""
        $this.IsContainer = $false
        $this.VirtualPath = ""
        $this.ContextPath = ""
        $this.Action = ""

        Write-Host $this.RequestUrl

        # webroot should be global from start script
        $webRootPath = ($this.Settings.webFolder) -replace "../", "/" -replace "./", "/" -replace "//", "/"
        if ($webRootPath.startswith("/")) {
            $webRootPath = $Global:RootPath + $webRootPath
            if (Test-Path $webRootPath) {
                $webRootPath = Resolve-Path -Path $webRootPath
            } else {
                write-host "webRootPath not found: $webRootPath"
                exit
            }
        }
        
        if ($this.Paths.Count -lt 2 -or $this.Paths[1] -eq "") {
            # Index page
            Write-Host "Index page"
            $this.RequestType = "Index"
            $this.Controller = "Index"
            # Write-Host "RequestType" $this.RequestType
            return
        }

        $testFilePath = Join-Path -Path $webRootPath.Path -ChildPath $this.LocalPath
        if (Test-Path $testFilePath -PathType Leaf) {
            # File page
            Write-Host "File resource"
            $this.RequestType = "File"
            $this.Controller = "File"
            $this.Action = "Stream"
            $this.ContextPath = Resolve-Path -Path $testFilePath
            # Write-Host "RequestType" $this.RequestType
            return
        }

        # Check if controller exists in the format "Show-{Controller}"
        $this.Controller = $this.Paths[1]
        $functionName = "Show-" + $this.Controller + "Controller"
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            # Controller page
            Write-Host "Controller page"
            $this.ControllerFunction = $functionName
            $this.RequestType = "Controller"
            # Write-Host "RequestType" $this.RequestType
            # return # no return as controller may need calculated paths
        }

        # Category page
        $this.Category = $this.Paths[1]
        $this.RequestType = "Category"
        
        # if ($this.Paths.Count -lt 3) {
        #     Write-Host "Category page with no folder index"
        # }

        $this.FolderIndex = $this.Paths[2] ?? 0
        $fIndex = $this.FolderIndex
        $folderSetting = $this.Settings."$($this.Category)Paths"
        $relativeIndex = 2
        if ($folderSetting -and $fIndex -ge 0 -and $fIndex -lt $folderSetting.Count) {
            $this.FolderPath = $folderSetting[$fIndex].pathString
            $relativeIndex = 3
        }

        if (Test-Path -Path $this.FolderPath) {
            $this.FolderPathResolved = Resolve-Path -Path $this.FolderPath            
        }

        if ($this.FolderPathResolved -eq "") {
            # Shared folder not exists
            Write-Host "404 page"
            $this.RequestType = "Error"
            Write-Host "RequestType" $this.RequestType
            return
        }

        if ($this.RelativePath[-1] -eq "view") {
            $this.RelativePath = $this.RelativePath[0..($this.RelativePath.Count - 2)]
            $this.Action = "view"
        }

        if ($this.Paths.Count -gt $relativeIndex) {
            $this.RelativePath = $this.Paths[$relativeIndex..($this.Paths.Count - 1)] -Join "/"

            $filter = ".zip|.cbz|.epub"
            if ($this.RelativePath -match [regex]::Escape($filter)) {
                # Split ProcessPath at the current containerFile
                $parts = $this.RelativePath -split [regex]::Escape($filter), 2
        
                # Assign the parts to $this.RelativePath and $this.VirtualPath
                $this.RelativePath = $parts[0] 
                $this.VirtualPath = $parts[1]
                $this.IsContainer = $true
            }
        }

        $testFilePath = Join-Path -Path $this.FolderPath -ChildPath $this.RelativePath        
        if (Test-Path -Path $testFilePath) {
            write-host "!!! $testFilePath exists !!!"
            $this.ContextPath = Resolve-Path -Path $testFilePath
            
            if ((Test-Path -Path $this.ContextPath -PathType Leaf) -and (-not $this.IsContainer)) {
                $this.Action = "View"
            } else {
                $this.Action = "List"
            }
        } else {
            write-host "!!! $testFilePath not exists !!!"
        }

        # write-host "r0" $this.RequestType
        # write-host "r1" $this.Controller
        # write-host "r2" $this.Category
        # write-host "r3" $this.FolderIndex
        # write-host "r4" $this.FolderPath
        # write-host "r5" $this.RelativePath
        # write-host "r6" $this.VirtualPath
        # write-host "r7" $this.ContextPath
    }

    RouteRequest() {
        switch ($this.RequestType) {
            "Controller" {
                & $this.ControllerFunction $this
            }
            "File" {
                BinaryHandler $this
            }
            "Index" {
                Show-HomeController $this
            }
            "Category" {
                # Show-CategoryController $this
                if ($this.Action -eq "View") {
                    Show-ItemController $this
                } elseif ($this.Action -eq "List") {
                    Show-CategoryController $this
                }
            }
            "Error" {
                # Show-ErrorController $this
                BinaryHandler $this
            }
            default {
               # Show-ErrorController $this 
            }
        }
    }

    RouteRequestOld() {
        switch ($this.Controller.ToLower()) {
            "shutdown" {
                # "`nListener shutting down..."
                $this.HttpListener.Stop()
                exit
            }
            "restart" {
                $stackListener = $this.HttpListener
                # "`nListener shutting down..."
                $this.HttpListener.Stop()
                
                # "`nListener starting..."
                $this.HttpListener.Start()
                
                # "`nRedirect to root to prevent infinite loop..."
                $requestObject = [RequestObject]::new($stackListener)
                RedirectRequest $requestObject "/"
            }
            "reload" {
                # "`nListener shutting down..."
                $this.HttpListener.Stop()
                
                # "`nReloading script, so the listener will restart..."
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
                $functionName = "Show-" + $this.Controller + "Controller"
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

}

