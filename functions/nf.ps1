# ---- nf
# create a new function, add template, open in helix or ISE
function nf {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [string] $FunctionName
    )

    # -- init
    
    # set filepath for new function
    $newFilePath = "$pwsh_scriptpath\functions\$FunctionName.ps1"

    # create .ps1 file for function
    ni -path $newFilePath -ItemType File
    
    # -- template

    # > add template to .ps1 file
    ac -path $newFilePath -val `
@"
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
"@
    # " # (extra quote is just to fix helix's formatting)

    # -- open .ps1 file for editing
    if ($host.Name -eq 'Windows PowerShell ISE Host') {
        ise $newFilePath
    } else {
        hx $newFilePath
    }
}
