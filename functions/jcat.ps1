# ---- jcat - cat JSON file and convert to powershell object

function jcat {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string] $Path
    )

    process {
        # that's it! that's the whole function! :D
        return (cat -raw $Path | ConvertFrom-Json -Depth 99)
    }
}
