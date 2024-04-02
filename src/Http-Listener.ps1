# Use the following commands to bind/unbind SSL cert
# netsh http add sslcert ipport=0.0.0.0:443 certhash=3badca4f8d38a85269085aba598f0a8a51f057ae "appid={00112233-4455-6677-8899-AABBCCDDEEFF}"
# netsh http delete sslcert ipport=0.0.0.0:443 
. ./Helper-Functions.ps1

$Global:JsonResult = $null

$HttpListener = New-Object System.Net.HttpListener
$HttpListener.Prefixes.Add("http://+:8888/")
$HttpListener.Prefixes.Add("https://+:443/")
$HttpListener.Start()
try {
	$stopFile = "./appoffline.htm"

	While ($HttpListener.IsListening -and !(Test-Path -Path $stopFile)) {

		# context variables
		$requestObject = [RequestObject]::new($HttpListener)
		Write-Output "localPath: $($requestObject.LocalPath)"
		Write-Output "url: $($requestObject.RequestUrl)"
		Write-Output "paths: $($requestObject.Paths)"
		Write-Output "controller: $($requestObject.Controller)"
    
		RouteRequest $requestObject
		Write-Output "end..." # Newline
		$requestObject = $null
	}
}
finally {
	$HttpListener.Stop()
}