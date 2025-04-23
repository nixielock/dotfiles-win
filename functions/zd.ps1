# zd (zork cd)
# literally just cd && zl
function zd {
    [CmdletBinding()]
    param (
        [parameter(Position=0, ValueFromPipeline)]
        [string] $Path = "$pwsh_home",

        [Alias('a')]
        [switch] $All
    )

    cd $Path && $All ? (zla) : (zl)
}

# "alias" function for -All flag
function zda { zd -a }
