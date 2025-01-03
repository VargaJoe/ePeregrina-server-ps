class peregrinaRequestObject {
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
    # webfolder path for system purposes on the webserver
    [string]$WebFolderPath
    # path to the file or folder on webserver or under the container
    [string]$VirtualPath
    [string]$ReducedLocalPath # Local path without the virtual path
    # action to be performed
    [string]$Action
    [string]$RequestType
    [bool]$IsResource
    
    peregrinaRequestObject([System.Net.HttpListener] $listener) {
        $this.Initialize($listener.GetContext())
    }

    peregrinaRequestObject([System.Net.HttpListenerContext]$context) {
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
        $this.WebFolderPath = ""
        $this.ReducedLocalPath = $this.LocalPath
        $this.Action = ""
        $this.IsResource = ""

        Write-Host "url" $this.RequestUrl
        Write-Host "referrer" $this.HttpRequest.Headers["Referer"]
        Write-Host "accept" $this.HttpRequest.Headers["Accept"]
        Write-Host "user agent" $this.HttpRequest.UserAgent

        if ($this.Paths.Count -lt 2 -or $this.Paths[1] -eq "") {
            # Index page
            Write-Host "Index page"
            $this.RequestType = "Index"
            $this.Controller = "Index"
            $this.ContextModelType = "home"
            return
        }

        # Category page
        $this.Category = $this.Paths[1]
        $this.RequestType = "Category"

        $webFolder = $this.Settings.webFolder
        write-host "!!!!!!!!!!!!!!!webFolder: $webFolder"
        $this.WebFolderPath = Resolve-Path -LiteralPath $webFolder
        write-host "!!!!!!!!!!!!!!!webFolder: $($this.WebFolderPath)"
        $folderSetting = $this.Settings."$($this.Category)Paths"
        if (-not $folderSetting) {
            Write-Host "404 page - category not set"
            $this.RequestType = "Error"
            $this.ContextModelType = "error404"
            return
        }

        if ($this.Paths.Count -lt 3) {
            Write-Host "Category page with no folder index"
            $this.ContextModelType = "categoryIndex"
            return
        }

        $this.FolderIndex = $this.Paths[2] 
        $fIndex = $this.FolderIndex
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
            $this.ContextModelType = "error404"
            Write-Host "RequestType" $this.RequestType
            return
        }

        # is this used somewhere?
        if ($this.RelativePath[-1] -eq "view") {
            $this.RelativePath = $this.RelativePath[0..($this.RelativePath.Count - 2)]
            $this.Action = "view"
        }
        
        Write-Host $this.UrlVariables
        if ($this.UrlVariables["action"]) {
            $this.Action = $this.UrlVariables["action"]
        }

        if ($this.Paths.Count -gt $relativeIndex) {
            $this.RelativePath = $this.Paths[$relativeIndex..($this.Paths.Count - 1)] -Join "/"

            $ufilter = ($this.Settings.containerFilter) -join "|"
            # $efilter = ($this.Settings.containerFilter | ForEach-Object { [regex]::Escape($_) }) -join "|"
            if ($this.RelativePath -match "\.($ufilter)") {
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
                Write-Host "NO MATCH!!!" $ufilter $this.RelativePath
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

        # TODO: untangle this mess
        # is there better way to distinguish resource request from content request?        
        # if (($this.HttpRequest.Headers["Referer"] -match "\.html" -and $this.ContextFileType -ne "html" -and $this.VirtualFileType -ne "html") `
        # -or ($this.HttpRequest.Headers["Referer"] -match "\.xhtml" -and $this.ContextFileType -ne "xhtml" -and $this.VirtualFileType -ne "xhtml") `
        # -or ($this.HttpRequest.Headers["Referer"] -match "\.pdf" -and ($this.ContextFileType -eq "pdf" -or ($this.ContextFileType -ne "pdf" -and $this.VirtualFileType -ne "html")))) {
        #     $this.IsResource = $true
        # }

        # workaround for testing pdf extracted html pages but fcuked up the other virtual paths
        if (
        ($this.VirtualPath -and $this.VirtualFileType -ne "html")
            # ($this.HttpRequest.Headers["Referer"] -match "\.html" -and $this.ContextFileType -ne "html" -and $this.VirtualFileType -ne "html") `
        # -or ($this.HttpRequest.Headers["Referer"] -match "\.xhtml" -and $this.ContextFileType -ne "xhtml" -and $this.VirtualFileType -ne "xhtml") #`
        # -or ($this.HttpRequest.Headers["Referer"] -match "\.pdf" -and $this.ContextFileType -eq "pdf")        
        ) {
            $this.IsResource = $true
        }
        
    }

    RouteRequest() {
        # action handler
        if ($this.Action) {
            Write-Host "ePeregrina action handler"
            ActionHandler($this)
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
            Write-Host "ePeregrina page main level - category list"
            # This is a ePeregrina page on main level
            # Show-CategoryIndexController $this

            PageHandler($this)
            return
        }

        # /category/folderindex
        if ($this.RequestType -eq "Category" -and $this.folderindex -gt -1 -and $this.RelativePath -eq "") {
            Write-Host "ePeregrina page main level - shared folders list on folder index"
            # This is a ePeregrina page on main level
            PageHandler($this)
            return
        }

        # /category/folderindex/relativepath.known + context IS NOT container
        if ($this.RequestType -eq "Category" -and $this.IsContainer -eq $false -and $this.ContextPageType -ne "" -and -not $this.IsResource) {
            Write-Host "ePeregrina page with a mapped file"
            # this is an ordinary content page
            PageHandler($this)
            return
        }

        # /category/folderindex/relativepath.known + context IS NOT container
        if ($this.RequestType -eq "Category" -and $this.IsContainer -eq $false -and $this.ContextPageType -ne "" -and $this.IsResource) {
            Write-Host "ePeregrina page with a mapped file REFERRED RESOURCE"
            BinaryHandler $this
            return
        }
        
        # /category/folderindex/relativepath.unknown + context IS container (folder)
        if ($this.RequestType -eq "Category" -and $this.RelativePath -ne "" -and $this.IsContainer -and $this.ContextPageType -eq "" -and $this.isfile -eq $false) {
            Write-Host "ePeregrina page with a folder - show list of contents"
            # if folder it should return the list of files            
            PageHandler($this)
            return
        }

        # /category/folderindex/relativepath.unknown + context IS container (file)
        if ($this.RequestType -eq "Category" -and $this.RelativePath -ne "" -and $this.IsContainer -and $this.ContextPageType -eq "" -and $this.isfile -and $this.VirtualPath -eq "") {
            Write-Host "ePeregrina page with an unknown file container - download the file"
            # if container file it should return the file
            BinaryHandler $this
            return
        }

#!!!    # /category/folderindex/relativepath.unknown + context IS NOT container
        if ($this.RequestType -eq "Category" -and $this.RelativePath -ne "" -and $this.IsContainer -eq $false -and $this.ContextPageType -eq "" -and $this.IsFile) {
            Write-Host "ePeregrina page with an unknown file - download the file"
            # it should return the file
            BinaryHandler $this
            return
        }

#!!!    # /category/folderindex/relativepath.known + context IS container (- is it matter if it is a container ot not?)
        # it is a previous logic - now it does not matter the context is container or not
        # contextType is the mapping for context file type - if it is set the appropriate controll will be called no matter what
        if ($this.RequestType -eq "Category" -and $this.RelativePath -ne "" -and $this.IsContainer -and $this.ContextPageType -ne "" -and $this.VirtualPath -eq "") {
            Write-Host "ePeregrina page with list of container file"
            # This is a list page of container file
            PageHandler($this)
            return
        }

        # /category/folderindex/relativepath/virtualpath.known + context IS container 
        if ($this.RequestType -eq "Category" -and $this.IsContainer -and $this.ContextPageType -ne "" -and $this.VirtualPath -ne "" -and -not $this.IsResource) {
            Write-Host "ePeregrina page with content of cointainer file on a virtual path"
            # This is a content page of container file
            PageHandler($this)
            return
        }
        
        # /category/folderindex/relativepath/virtualpath.known + context IS container 
        if ($this.RequestType -eq "Category" -and $this.IsContainer -and $this.ContextPageType -ne "" -and $this.VirtualPath -ne "" -and $this.IsResource) {
            Write-Host "ePeregrina page with content of cointainer file on a virtual path REFERRED RESOURCE"
            # it should return the file
            VirtualBinaryHandler $this
            return
        }

#!!!    # /category/folderindex/relativepath/virtualpath.unknown + context IS container 
        if ($this.RequestType -eq "Category" -and $this.RelativePath -ne "" -and $this.VirtualPath -ne "" -and $this.IsContainer -and $this.ContextPageType -eq "") {
            Write-Host "ePeregrina page with an unknown file in a container file - download the file"
            # it should return the file
            VirtualBinaryHandler $this
            return
        }


        if ($this.RequestType -eq "Error") {
            Write-Host "404 page"
            # Error page is handled by the ErrorController
            PageHandler($this)
            return
        }
    }
}

