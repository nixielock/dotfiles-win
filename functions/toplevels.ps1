function toplevels {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [string] $Path = "$PWD",

        [Alias('w')]
        [switch] $IncludeWorkingDirectory
    )

    process {
        $parents = @()
        $current = $Path
        while ($current -match '\\') {
            $current = $current -replace '\\[^\\]*$', ''
            $parents += $current
        }
        $parents
    }
}
