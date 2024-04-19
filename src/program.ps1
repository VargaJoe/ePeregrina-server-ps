# Use the following commands to bind/unbind SSL cert
# netsh http add sslcert ipport=0.0.0.0:443 certhash=3badca4f8d38a85269085aba598f0a8a51f057ae "appid={00112233-4455-6677-8899-AABBCCDDEEFF}"
# netsh http delete sslcert ipport=0.0.0.0:443 

# Load helper functions from the Utils folder
Get-ChildItem -LiteralPath ./models -Filter *.ps1 | ForEach-Object {
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
$HttpListener.Prefixes.Add("http://+:8888/")
$HttpListener.Prefixes.Add("https://+:443/")
$HttpListener.Start()

try {
	$stopFile = "./appoffline.htm"

	While ($HttpListener.IsListening -and !(Test-Path -Path $stopFile)) {
		$Global:responseClosed = $false
		Write-Host "`n`n"
		$context = $HttpListener.GetContext()
				
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
	}
}
finally {
	$HttpListener.Stop()
	"stop listener" | Out-File -Append -FilePath "./log.txt"
}