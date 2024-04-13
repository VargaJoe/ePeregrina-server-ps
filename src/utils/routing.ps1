# function RouteRequest($requestObject) {
#     switch ($requestObject.Controller.ToLower()) {
#         "shutdown" {
#             Write-Host "`nListener shutting down..."
#             $requestObject.HttpListener.Stop()
#             exit
#         }
#         "restart" {
#             Write-Host "`nListener shutting down..."
#             $requestObject.HttpListener.Stop()
            
#             Write-Host "`nListener starting..."
#             $requestObject.HttpListener.Start()
            
#             Write-Host "`nRedirect to root to prevent infinite loop..."
#             $requestObject = [RequestObject]::new($HttpListener)
#             RedirectRequest $requestObject "/"
#         }
#         "reload" {
#             Write-Host "`nListener shutting down..."
#             $requestObject.HttpListener.Stop()
            
#             Write-Host "`nReloading script, so the listener will restart..."
#             . ./Http-Listener.ps1
#         }
#         "" {
#             Show-HomeController $requestObject
#         }
#         "index" {
#             Show-HomeController $requestObject
#         }
#         default {
#             # The function name should be in the format "Show-{Controller}"
#             $functionName = "Show-" + $requestObject.Controller + "Controller"
#             if (Get-Command $functionName -ErrorAction SilentlyContinue) {
#                 # Call the function dynamically based on the controller name if exists
#                 & $functionName $requestObject
#             } else {
#                 # If the controller does not exist, treat it as a binary request
#                 BinaryHandler $requestObject
#             }     
#         }
#     }
# }

# # additional routing:
# # - id: /category/{id}
# # - path: / category/{category_index}/{relative path}
# # - could be mvc like routing: /{controller}/{action}/{id}

# function RedirectRequest($requestObject, $newUrl) {
#     $response = $requestObject.HttpContext.Response
#     $response.StatusCode = 302
#     $response.RedirectLocation = $newUrl
#     $response.Close()
# }