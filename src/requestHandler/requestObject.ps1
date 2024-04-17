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
    [bool]$IsFile
    [string]$ContextFileType
    [string]$ContextModelType
    [string]$VirtualFileType
    [string]$ContextPageType
    [string]$VirtualModelType
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
    [bool]$IsResource
    
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
        $this.FolderIndex = -1
        $this.FolderPath = ""
        $this.FolderPathResolved = ""
        $this.RelativePath = ""
        $this.IsContainer = $false
        $this.IsFile = $false
        $this.ContextFileType = ""
        $this.ContextModelType = ""
        $this.VirtualFileType = ""
        $this.ContextPageType = ""
        $this.VirtualModelType = ""      
        $this.VirtualPath = ""
        $this.ContextPath = ""
        $this.ReducedLocalPath = $this.LocalPath
        $this.Action = ""
        $this.IsResource = ""

        Write-Host "`n`nurl" $this.RequestUrl
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
        
        if ($this.Paths.Count -lt 2 -or $this.Paths[1] -eq "") {
            # Index page
            Write-Host "Index page"
            $this.RequestType = "Index"
            $this.Controller = "Index"
            $this.ContextModelType = "home"
            return
        }

        $testFilePath = Join-Path -Path $webRootPath.Path -ChildPath $this.LocalPath
        if (Test-Path -LiteralPath $testFilePath -PathType Leaf) {
            # File page
            Write-Host "File resource"
            $this.RequestType = "File"
            $this.Controller = "File"
            $this.Action = "Stream"
            $this.ContextPath = Resolve-Path -LiteralPath $testFilePath
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
            return 
        }

        # Category page
        $this.Category = $this.Paths[1]
        $this.RequestType = "Category"
        if ($this.Paths.Count -lt 3) {
            Write-Host "Category page with no folder index"
            $this.ContextModelType = "categoryIndex"
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
        $this.ContextModelType = "categoryFolder"

        if (Test-Path -LiteralPath $this.FolderPath) {
            $this.FolderPathResolved = Resolve-Path -LiteralPath $this.FolderPath            
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
                $index = 0
                $match = [Regex]::Match($this.RelativePath, $ufilter)
                if ($match.Success) {
                    $index = $match.Index + $match.Value.Length
                }
                $this.VirtualPath = $this.RelativePath.Substring($index)
                $this.RelativePath = $this.RelativePath.Substring(0, $index)
                $this.ReducedLocalPath = $this.LocalPath.Substring(0, $this.LocalPath.Length - $this.VirtualPath.Length)
                
                # it is a container file
                $this.IsContainer = $true
                $this.IsFile = $true
            } else {
                Write-Host "NO MATCH!!!" $efilter $this.RelativePath
            }
        }

        $testFilePath = Join-Path -Path $this.FolderPath -ChildPath $this.RelativePath        
        if (Test-Path -LiteralPath $testFilePath) {
            $this.ContextPath = Resolve-Path -LiteralPath $testFilePath
            
            if ((Test-Path -LiteralPath $this.ContextPath -PathType Leaf)) {
                # Get the file extension from ContextPath so the addressed file can be opened
                $this.ContextFileType = [System.IO.Path]::GetExtension($this.ContextPath).TrimStart(".")
                $this.ContextModelType = $this.Settings.FileTypes.($this.ContextFileType)
                
                # Get the file extension from VirtualPath so page will work even with addressed files inside container files
                $this.VirtualFileType = [System.IO.Path]::GetExtension($this.VirtualPath).TrimStart(".")
                $this.VirtualModelType = $this.Settings.FileTypes.($this.VirtualFileType)

                $typeIndexer = if ($this.VirtualFileType) { $this.VirtualFileType } else { $this.ContextFileType }
                $this.ContextPageType = $this.Settings.FileTypes.($typeIndexer)                

                # If FileType is $null, the file extension didn't match any key in the FileTypes dictionary
                if ($null -eq $this.ContextPageType) {
                    Write-Host "!!! No PageType found for .$($this.VirtualFileType) !!!"
                }
                
                $this.IsFile = $true
            } else {
                Write-Host "Folder!!!"
                $this.IsContainer = $true
            }
        } else {
            write-host "!!! $testFilePath not exists !!!"
        }

        # is there better way to distinguish resource request from content request?        
        if (($this.HttpRequest.Headers["Referer"] -match "\.html" -and $this.ContextFileType -ne "html" -and $this.VirtualFileType -ne "html") `
        -or ($this.HttpRequest.Headers["Referer"] -match "\.pdf" -and $this.ContextFileType -eq "pdf")) {
            $this.IsResource = $true
        }
    }

    RouteRequest() {
        # /controller/action/parameter/s
        if ($this.RequestType -eq "Controller") {
            Write-Host "Controller page"
            # Controller mode is handled by the controller function via naming convention
            & $this.ControllerFunction $this
            return
        }

        # /favicon.ico
        # /styles/style.css
        if ($this.RequestType -eq "File") {
            Write-Host "File resource"
            # If file exists on path file mode is handled by the binary handler
            BinaryHandler $this
            return
        }

        # /
        # /index
        # /home
        if ($this.RequestType -eq "Index") {
            Write-Host "Index page"
            # Index page is handled by the HomeController
            # Show-HomeController $this
            
            PageHandler($this)
            return
        }

        # peregrine ebook server url structure
        # /category/folderindex/relativepath/virtualpath

        # /category
        if ($this.RequestType -eq "Category" -and $this.folderindex -eq -1) {
            Write-Host "Pelegrina page main level - category list"
            # This is a Pelegrina page on main level
            # Show-CategoryIndexController $this

            PageHandler($this)
            return
        }

        # /category/folderindex
        if ($this.RequestType -eq "Category" -and $this.folderindex -gt -1 -and $this.RelativePath -eq "") {
            Write-Host "Pelegrina page main level - shared folders list on folder index"
            # This is a Pelegrina page on main level
            # Show-CategoryFolderController $this

            PageHandler($this)
            return
        }

        # /category/folderindex/relativepath.known + context IS NOT container
        if ($this.RequestType -eq "Category" -and $this.IsContainer -eq $false -and $this.ContextPageType -ne "" -and -not $this.IsResource) {
            Write-Host "Pelegrina page with a mapped file"
            # this is an ordinary content page
            
            # $functionName = "Show-" + $this.ContextPageType + "Controller"
            # if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            #     Write-Host "function" $functionName
            #     & $functionName $this
            # } else {
            #     Write-Host "function not found" $functionName            
            # }

            PageHandler($this)
            return
        }

        # /category/folderindex/relativepath.known + context IS NOT container
        if ($this.RequestType -eq "Category" -and $this.IsContainer -eq $false -and $this.ContextPageType -ne "" -and $this.IsResource) {
            Write-Host "Pelegrina page with a mapped file REFERRED RESOURCE"
            BinaryHandler $this
            return
        }
        
        # /category/folderindex/relativepath.unknown + context IS container (folder)
        if ($this.RequestType -eq "Category" -and $this.RelativePath -ne "" -and $this.IsContainer -and $this.ContextPageType -eq "" -and $this.isfile -eq $false) {
            Write-Host "Pelegrina page with a folder - show list of contents"
            # if folder it should return the list of files            
            # Show-CategoryFolderController $this

            PageHandler($this)
            return
        }

        # /category/folderindex/relativepath.unknown + context IS container (file)
        if ($this.RequestType -eq "Category" -and $this.RelativePath -ne "" -and $this.IsContainer -and $this.ContextPageType -eq "" -and $this.isfile -and $this.VirtualPath -eq "") {
            Write-Host "Pelegrina page with an unknown file container - download the file"
            # if container file it should return the file
            BinaryHandler $this
            return
        }

#!!!    # /category/folderindex/relativepath.unknown + context IS NOT container
        if ($this.RequestType -eq "Category" -and $this.RelativePath -ne "" -and $this.IsContainer -eq $false -and $this.ContextPageType -eq "") {
            Write-Host "Pelegrina page with an unknown file - download the file"
            # it should return the file
            BinaryHandler $this
            return
        }

#!!!    # /category/folderindex/relativepath.known + context IS container (- is it matter if it is a container ot not?)
        # it is a previous logic - now it does not matter the context is container or not
        # contextType is the mapping for context file type - if it is set the appropriate controll will be called no matter what
        if ($this.RequestType -eq "Category" -and $this.RelativePath -ne "" -and $this.IsContainer -and $this.ContextPageType -ne "" -and $this.VirtualPath -eq "") {
            Write-Host "Pelegrina page with list of container file"
            # This is a list page of container file
            
            # $functionName = "Show-" + $this.ContextPageType + "Controller"
            # if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            #     Write-Host "function" $functionName
            #     & $functionName $this
            # } else {
            #     Write-Host "function not found" $functionName
            # }

            PageHandler($this)
            return
        }

        # /category/folderindex/relativepath/virtualpath.known + context IS container 
        if ($this.RequestType -eq "Category" -and $this.IsContainer -and $this.ContextPageType -ne "" -and $this.VirtualPath -ne "" -and -not $this.IsResource) {
            Write-Host "Pelegrina page with content of cointainer file on a virtual path"
            # This is a content page of container file
            
            # $functionName = "Show-" + $this.ContextPageType + "Controller"
            # if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            #     Write-Host "function" $functionName
            #     & $functionName $this
            # } else {
            #     Write-Host "function not found" $functionName
            # }

            PageHandler($this)
            return
        }
        
        # /category/folderindex/relativepath/virtualpath.known + context IS container 
        if ($this.RequestType -eq "Category" -and $this.IsContainer -and $this.ContextPageType -ne "" -and $this.VirtualPath -ne "" -and $this.IsResource) {
            Write-Host "Pelegrina page with content of cointainer file on a virtual path REFERRED RESOURCE"
            # it should return the file
            VirtualBinaryHandler $this
            return
        }

#!!!    # /category/folderindex/relativepath/virtualpath.unknown + context IS container 
        if ($this.RequestType -eq "Category" -and $this.RelativePath -ne "" -and $this.VirtualPath -ne "" -and $this.IsContainer -and $this.ContextPageType -eq "") {
            Write-Host "Pelegrina page with an unknown file in a container file - download the file"
            # it should return the file
            VirtualBinaryHandler $this
            return
        }


        if ($this.RequestType -eq "Error") {
            Write-Host "404 page"
            # Error page is handled by the ErrorController
            # Show-ErrorController $this
            BinaryHandler $this
            return
        }
    }
}

