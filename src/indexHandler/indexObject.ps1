class IndexObject {
    [string]$indexFilePath = "./index.json"
    [PSCustomObject]$Index = @{}

    IndexObject() {
        if (Test-Path $this.indexFilePath) {
            $this.Index = Get-Content $this.indexFilePath | ConvertFrom-Json
        }
    }

    # Method to add a new ID-path mapping to the index
    [void] AddIndexEntry([string]$id, [string]$path) {
        $this.index[$id] = $path
        $this.SaveIndexToFile()
    }

    # Method to save the index to the file
    [void] SaveIndexToFile() {
        $this.index | ConvertTo-Json | Set-Content $this.indexFilePath
    }

    # Function to get the path associated with an ID
    [string]  GetPathById([string]$id) {
        return $this.index[$id]
    }

    # # Example usage:
    # # Add a new entry to the index
    # AddIndexEntry -id "123" -path "C:\example\file.txt"

    # # Get the path associated with an ID
    # $path = GetPathById -id "123"
    # Write-Output "Path for ID '123': $path"

    
    # function Get-Index {
    #     [CmdletBinding()]
    #     param (
    #         [Parameter(Mandatory = $true)]
    #         [string]$Path
    #     )

    #     $index = 0
    #     Get-Content $Path | ForEach-Object {
    #         $index++
    #         [PSCustomObject]@{
    #             Index = $index
    #             Line = $_
    #         }
    #     }
    # }
}