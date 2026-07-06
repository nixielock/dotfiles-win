# ---- jpretty - pretty-ify input JSON via conversion to and from powershell data

function jpretty {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [string] $InputObject,

        [parameter(ValueFromPipelineByPropertyName)]
        [Alias('p')]
        [string] $Path,

        [Alias('d')]
        [switch] $Display,

        [Alias('n')]
        [switch] $NoPaging
    )

    process {
        if ($Path) {
            $InputObject = cat -raw $Path
        }

        if ($Display) {
            if (-not $NoPaging -and ($InputObject -split "`n").Count -gt ($Host.UI.RawUI.WindowSize.Height - 3)) {
                if ($Path) {
                    $filename = $Path -replace '.*\\([^\\]+)$', '$1'
                    $InputObject | ConvertFrom-Json -Depth 20 |
                        ConvertTo-Json -Depth 20 |
                        bat -f --file-name "$filename" | less -R
                } else {
                    $InputObject | ConvertFrom-Json -Depth 20 |
                        ConvertTo-Json -Depth 20 |
                        bat -f -l json | less -R
                }
            } else {
                if ($Path) {
                    $filename = $Path -replace '.*\\([^\\]+)$', '$1'
                    $InputObject | ConvertFrom-Json -Depth 20 |
                        ConvertTo-Json -Depth 20 |
                        bat --file-name "$filename"
                } else {
                    $InputObject | ConvertFrom-Json -Depth 20 |
                        ConvertTo-Json -Depth 20 |
                        bat -l json
                }
            }
        } else {
            return ($InputObject | ConvertFrom-Json -Depth 20 | ConvertTo-Json -Depth 20)
        }
    }
}
