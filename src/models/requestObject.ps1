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
    # url path
    [string]$RelativePath
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
    
    RequestObject([System.Net.HttpListener] $listener) {
        $this.HttpListener = $listener
        $this.HttpContext = $listener.GetContext()
        $this.HttpRequest = $this.HttpContext.Request
        $this.RequestUrl = $this.HttpContext.Request.Url
        $this.LocalPath = $this.RequestUrl.LocalPath
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
        $this.RelativePath = ""
        $this.VirtualPath = ""

        if ($this.Paths.Count -lt 2) {
            return
        }

        $this.Controller = $this.Paths[1]

        # Check if controller exists in the format "Show-{Controller}"
        $functionName = "Show-" + $this.Controller + "Controller"
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            # Call the function dynamically based on the controller name if exists
            $this.ControllerFunction = $functionName
        }

        $this.Category = $this.Paths[1]
        
        if ($this.Paths.Count -lt 3) {
            return
        }

        $this.FolderIndex = $this.Paths[2]       
        $fIndex = $this.FolderIndex
        $folderSetting = $this.Settings."$($this.Category)Paths"
        $relativeIndex = 2
        if ($folderSetting -and $fIndex -ge 0 -and $fIndex -lt $folderSetting.Count) {
            $this.FolderPath = $folderSetting[$fIndex].pathString
            $relativeIndex = 3
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
            }
        }

        write-host "r1" $this.Controller
        write-host "r2" $this.Category
        write-host "r3" $this.FolderIndex
        write-host "r4" $this.FolderPath
        write-host "r5" $this.RelativePath
        write-host "r6" $this.VirtualPath
    }

    RouteRequest() {
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

