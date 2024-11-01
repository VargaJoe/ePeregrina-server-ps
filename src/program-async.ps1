param (
    [int]$ServicePort = 8898
)

function New-ScriptBlockCallback 
    {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
        param(
            [parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [scriptblock]$Callback
        )

        # Is this type already defined?
        if (-not ( 'CallbackEventBridge' -as [type])) {
            Add-Type @' 
                using System; 
 
                public sealed class CallbackEventBridge { 
                    public event AsyncCallback CallbackComplete = delegate { }; 
 
                    private CallbackEventBridge() {} 
 
                    private void CallbackInternal(IAsyncResult result) { 
                        CallbackComplete(result); 
                    } 
 
                    public AsyncCallback Callback { 
                        get { return new AsyncCallback(CallbackInternal); } 
                    } 
 
                    public static CallbackEventBridge Create() { 
                        return new CallbackEventBridge(); 
                    } 
                } 
'@
        }
        $bridge = [callbackeventbridge]::create()
        Register-ObjectEvent -InputObject $bridge -EventName callbackcomplete -Action $Callback -MessageData $args > $null
        $bridge.Callback
    }

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

Write-host "Start Peregrina Webserver on Port $($ServicePort)"
"new listener" | Out-File -Append -FilePath "./log.txt"
$HttpListener = New-Object System.Net.HttpListener
$HttpListener.Prefixes.Add("http://+:"+$($ServicePort)+"/")
# $HttpListener.Prefixes.Add("https://+:443/")
$HttpListener.Start()

Write-host "Start-WebserverAsync:Prepare RequestListener code"
$requestListener = {
            [cmdletbinding()]
            param($result)

            [System.Net.HttpListener]$HttpListener = $result.AsyncState;
            $context = $HttpListener.EndGetContext($result);    # waitfor request to complete

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

            # sample listener
            $request = $context.Request                     # Collect Request
            $response = $context.Response                   # get Response Object
            write-host "got $($request.RawURL)"
            switch ($request.RawURL) {                      # Handle Request based on the URL 
                "/quit" {$HttpListener.Stop(); break}           # stop listener and exit handler
                "/date" {$message = "WebServer Time $((get-date).DateTime)"}
                Default {$message = "404 Page not found  use /quit to end webserver or /date to get system date";}
            }
            $response.ContentType = 'text/html';
            [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
            $response.ContentLength64 = $buffer.length
            $output = $response.OutputStream
            $output.Write($buffer, 0, $buffer.length)
            $output.Close()
    } 

try {
    $context = $HttpListener.BeginGetContext((New-ScriptBlockCallback -Callback $requestListener), $HttpListener)
    Write-host "Start-WebserverAsync:Start Async listener Processing - Press any key to stop"
    [datetime]$timestamp = Get-date
    [long]$count = 60

	$stopFile = "./appoffline.htm"

	While ($HttpListener.IsListening -and !(Test-Path -Path $stopFile)) {
		$Global:responseClosed = $false
		Write-Host "`n`n"
		If ($context.IsCompleted -and $HttpListener.IsListening) {
            # start new Callback for next request. Do it at the start to handle quit events first     
            $context = $HttpListener.BeginGetContext((New-ScriptBlockCallback -Callback $requestListener), $HttpListener)
        }
		
        if ($count -ge 60) {
            Write-host ; Write-Host "$(([System.DateTime]::UtcNow).tostring("u")) " -nonewline
            $count=0
        }
        if ( ((get-date) - $timestamp).totalseconds -gt 1) {
            write-host "." -NoNewline        
            $count ++
            $timestamp = Get-date
        }
	}
}
finally {
	$HttpListener.Stop()
    $HttpListener.Close()
    Write-host "Stop Pregerina Webserver"
	"stop listener" | Out-File -Append -FilePath "./log.txt"
}