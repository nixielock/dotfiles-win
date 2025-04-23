# ---- linkreplace - for moving configs and other things into a centralised location!

$pwsh_linkDir = "~\awldrive\.config\symlinks"

function linkreplace {
    [CmdletBinding()]
    param (
        # name to giev the new symlink in the register
        [parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Name,
        
        # path to the existing file/directory to be symlink-ified
        [parameter(Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Path,
    )
    
    process {
        $pathItem = (gi $Path -ea Stop)
        $isDirectory = $pathItem.PSIsContainer
    }
}
