param (
    [int]$ServicePort = 8898
)

# Use the following commands to bind/unbind SSL cert
# netsh http add sslcert ipport=0.0.0.0:443 certhash=3badca4f8d38a85269085aba598f0a8a51f057ae "appid={00112233-4455-6677-8899-AABBCCDDEEFF}"
# netsh http delete sslcert ipport=0.0.0.0:443 

# Load helper functions from the Utils folder
Get-ChildItem -LiteralPath ./models -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -LiteralPath ./actions -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -LiteralPath ./requestHandler -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -LiteralPath ./utils -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

# Load controllers from the Controllers folder
Get-ChildItem -LiteralPath ./controllers -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

$Global:JsonResult = $null
$Global:RootPath = $PSScriptRoot
$Global:responseClosed = $true

"new listener" | Out-File -Append -FilePath "./log.txt"
$HttpListener = New-Object System.Net.HttpListener
$HttpListener.Prefixes.Add("http://+:$($ServicePort)/")
$HttpListener.Prefixes.Add("https://+:443/")
$HttpListener.Start()

$stopFile = "./appoffline.htm"

# Function to handle incoming requests asynchronously
function Handle-Request {
    param (
        [System.Net.HttpListenerContext]$context
    )

    $runspace = [powershell]::Create().AddScript({
        param ($context)
        try {
            $Global:responseClosed = $false

            # context variables
            if (-not $Global:responseClosed) {
                Write-Host "StaticRequestObject"
                $requestObject = [StaticRequestObject]::new($context)
                $requestObject.RouteRequest()
            }

            if (-not $Global:responseClosed) {
                Write-Host "ControllerRequestObject"
                $requestObject = [ControllerRequestObject]::new($context)
                $requestObject.RouteRequest()
            }

            if (-not $Global:responseClosed) {
                Write-Host "peregrinaRequestObject"
                $requestObject = [peregrinaRequestObject]::new($context)
                $requestObject.RouteRequest()
            }

            if (-not $Global:responseClosed) {
                Write-Host "ErrorRequestObject"
                $requestObject = [ErrorRequestObject]::new($context)
                $requestObject.RouteRequest()
            }
        } catch {
            Write-Error $_
        } finally {
            $context.Response.Close()
        }
    }).AddArgument($context).BeginInvoke()
}

# Function to begin listening for requests asynchronously
function Begin-GetContext {
    $HttpListener.BeginGetContext({
        param ($result)
        try {
            $context = $HttpListener.EndGetContext($result)
            Handle-Request -context $context
        } catch {
            Write-Error $_
        } finally {
            if ($HttpListener.IsListening -and !(Test-Path -Path $stopFile)) {
                Begin-GetContext
            }
        }
    }, $null)
}

try {
    Begin-GetContext

    # Keep the script running until the stop file is created
    while ($HttpListener.IsListening -and !(Test-Path -Path $stopFile)) {
        Start-Sleep -Seconds 1
    }
}
finally {
    $HttpListener.Stop()
    "stop listener" | Out-File -Append -FilePath "./log.txt"
}