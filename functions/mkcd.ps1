# mkcd
# create a new directory and set it as the current working directory
function mkcd {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [string] $Path
    )

    mkdir $Path | Out-Null &&
        cd $Path &&
        ro "created |@h|$($PWD.Path) |@|and navigated to it!"
}
