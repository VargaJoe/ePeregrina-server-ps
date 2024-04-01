# Use the following commands to bind/unbind SSL cert
# netsh http add sslcert ipport=0.0.0.0:443 certhash=3badca4f8d38a85269085aba598f0a8a51f057ae "appid={00112233-4455-6677-8899-AABBCCDDEEFF}"
# netsh http delete sslcert ipport=0.0.0.0:443 
$Global:JsonResult = $null

. ./Helper-Functions.ps1

$HttpListener = New-Object System.Net.HttpListener
$HttpListener.Prefixes.Add("http://+:8888/")
$HttpListener.Prefixes.Add("https://+:443/")
$HttpListener.Start()
try {
	$stopFile = "./appoffline.htm"

	While ($HttpListener.IsListening -and !(Test-Path -Path $stopFile)) {

		$Result = 0
	
		# context variables
		$context = $HttpListener.GetContext()
		$requestObject = [RequestObject]::new($context)


		Write-Output "localPath: $($requestObject.LocalPath)"
		Write-Output "url: $($requestObject.RequestUrl)"
		Write-Output "paths: $($requestObject.Paths)"
		Write-Output "controller: $($requestObject.Controller)"
    
	
		if ($controller -eq "shutdown") {
			Write-Host "`nListener shutting down..."
			$HttpListener.Stop()
			break;
		}
	
		# if (-Not [string]::IsNullOrEmpty(($requestObject.Controller))) {
		# 	Write-Host plot: ($requestObject.Controller)
		# 	& ../Run.ps1 -plot $Plot
		# 	$Result = $LASTEXITCODE
		# }
	
		$HttpResponse = $context.Response
		$HttpResponse.Headers.Add("Content-Type", "application/json")
		$HttpResponse.Headers.Add("Access-Control-Allow-Origin", "http://172.17.17.195:8080")
		$HttpResponse.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
		$HttpResponse.StatusCode = 200
		$jsondata = @{Step = $Plot; ExitCode = $Result; Output = $JsonResult } 
		$object = new-object psobject -Property $jsondata 
		$jsondata = $object | ConvertTo-Json -depth 100
		$ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($jsondata)
		$HttpResponse.ContentLength64 = $ResponseBuffer.Length
		$HttpResponse.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
		$HttpResponse.Close()
		$Plot = ""
		Write-Output "end..." # Newline
	}
}
finally {
	$HttpListener.Stop()
}