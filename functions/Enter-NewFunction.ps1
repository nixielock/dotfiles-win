# load the function globally when script is called

# Enter-NewFunction / nf
# creates a new function, adds initial comments, and edits in ISE
function Enter-NewFunction {
    [CmdletBinding()]
    [Alias('nf')]
    param (
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [string] $FunctionName
    )

    $newFilePath = "$scriptpath\functions\$FunctionName.ps1"

    New-Item -Path $newFilePath -ItemType File
    Add-Content -Path $newFilePath -Value @"
# $FunctionName
# load the function globally when script is called

function $FunctionName {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [string] $Parameter
    )
    
    process {
        # function body
    }
}
"@ # " # (extra quote is just to fix helix's formatting)

    if ($host.Name -eq 'Windows PowerShell ISE Host') {
        ise $newFilePath
    } else {
        hx $newFilePath
    }
}
