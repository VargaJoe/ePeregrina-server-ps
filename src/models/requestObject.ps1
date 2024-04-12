class RequestObject {
    [System.Net.HttpListener]$HttpListener
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
    [string]$ContextFileType
    [string]$ContextModelType
    [string]$VirtualFileType
    [string]$ContextPageType
    # index of item in folder
    [string]$ItemIndex
    # path to the file or folder on the webserver
    [string]$ContainerPath
    # parent path to the file or folder on the webserver
    [string]$ContextPath
    # path to the file or folder on webserver or under the container
    [string]$VirtualPath
    [string]$ReducedLocalPath # Local path without the virtual path
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

        # https://domain/category/folderindex/relativepath/virtualpath
        # default
        $this.Controller = ""
        $this.ControllerFunction = ""
        $this.Category = ""
        $this.FolderIndex = 0
        $this.FolderPath = ""
        $this.FolderPathResolved = ""
        $this.RelativePath = ""
        $this.IsContainer = $false
        $this.ContextFileType = ""
        $this.ContextModelType = ""
        $this.VirtualFileType = ""
        $this.ContextPageType = ""        
        $this.VirtualPath = ""
        $this.ContextPath = ""
        $this.ReducedLocalPath = $this.LocalPath
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

            $ufilter = ($this.Settings.containerFilter) -join "|"
            $efilter = ($this.Settings.containerFilter | ForEach-Object { [regex]::Escape($_) }) -join "|"
            if ($this.RelativePath -match ".($ufilter)") {
                Write-Host "MATCH!!!" $ufilter $this.RelativePath
                
                # $parts = $this.RelativePath -split "$ufilter"
                # Write-Host "p1" "["$parts"]"
                # $parts = $this.RelativePath -replace ".*$ufilter", ""
                # Write-Host "p1" "["$parts"]"

                $parts = ""
                $index = 0
                $match = [Regex]::Match($this.RelativePath, $ufilter)
                if ($match.Success) {
                    $index = $match.Index + $match.Value.Length
                }
                $this.VirtualPath = $this.RelativePath.Substring($index)
                $this.RelativePath = $this.RelativePath.Substring(0, $index)
                $this.ReducedLocalPath = $this.LocalPath.Substring(0, $this.LocalPath.Length - $this.VirtualPath.Length)
                
                Write-Host $this.VirtualPath
                
                # Assign the parts to $this.RelativePath and $this.VirtualPath
                # $this.RelativePath = $parts[0] 
                # $this.VirtualPath = $parts[1]
                $this.IsContainer = $true
            } else {
                Write-Host "NO MATCH!!!" $efilter $this.RelativePath
            }
        }

        $testFilePath = Join-Path -Path $this.FolderPath -ChildPath $this.RelativePath        
        if (Test-Path -Path $testFilePath) {
            write-host "!!! $testFilePath exists !!!"
            $this.ContextPath = Resolve-Path -Path $testFilePath
            
            if ((Test-Path -Path $this.ContextPath -PathType Leaf)) {
                Write-Host "File!!!"
                # $this.Action = "View"

                # Get the file extension from ContextPath so the addressed file can be opened
                $this.ContextFileType = [System.IO.Path]::GetExtension($this.ContextPath).TrimStart(".")
                $this.ContextModelType = $this.Settings.FileTypes.($this.ContextFileType)
                
                # Get the file extension from VirtualPath so page will work even with addressed files inside container files
                $this.VirtualFileType = [System.IO.Path]::GetExtension($this.VirtualPath).TrimStart(".")
                $typeIndexer = if ($this.VirtualFileType) { $this.VirtualFileType } else { $this.ContextFileType }
                $this.ContextPageType = $this.Settings.FileTypes.($typeIndexer)

                # If FileType is $null, the file extension didn't match any key in the FileTypes dictionary
                if ($null -eq $this.ContextPageType) {
                    Write-Host "!!! No PageType found for .$($this.VirtualFileType) !!!"
                }
            } else {
                Write-Host "Folder!!!"
                $this.IsContainer = $true
                # $this.Action = "List"
            }
        } else {
            write-host "!!! $testFilePath not exists !!!"
        }
    }

    RouteRequest() {
        if ($this.RequestType -eq "Controller") {
            # Controller mode is handled by the controller function via naming convention
            & $this.ControllerFunction $this
            return
        }

        if ($this.RequestType -eq "File") {
            # If file exists on path file mode is handled by the binary handler
            BinaryHandler $this
            return
        }

        if ($this.RequestType -eq "Index") {
            # Index page is handled by the HomeController
            Show-HomeController $this
            return
        }

        if ($this.RequestType -eq "Category" -and $this.IsContainer -and $this.ContextPageType -eq "") {
            # This is a category page on main level
            Show-CategoryController $this
            return
        }

        if ($this.RequestType -eq "Category" -and $this.IsContainer -and $this.ContextPageType -ne "" -and $this.VirtualPath -eq "") {
            # This is a list page of container file
            $functionName = "Show-" + $this.ContextPageType + "Controller"
            if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                Write-Host "function" $functionName
                & $functionName $this
            } else {
                Write-Host "function not found" $functionName
            }
            return
        }

        if ($this.RequestType -eq "Category" -and $this.IsContainer -and $this.ContextPageType -ne "" -and $this.VirtualPath -ne "") {
            # This is a content page of container file
            $functionName = "Show-" + $this.ContextPageType + "Controller"
            if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                Write-Host "function" $functionName
                & $functionName $this
            } else {
                Write-Host "function not found" $functionName
            }
            return
        }

        if ($this.RequestType -eq "Category" -and $this.IsContainer -eq $false) {
            # this is an ordinary content page
            $functionName = "Show-" + $this.ContextPageType + "Controller"
            if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                Write-Host "function" $functionName
                & $functionName $this
            } else {
                Write-Host "function not found" $functionName
            }
        }

        if ($this.RequestType -eq "Error") {
            # Error page is handled by the ErrorController
            # Show-ErrorController $this
            BinaryHandler $this
            return
        }
    }
}

