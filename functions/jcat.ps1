# ---- jcat - cat JSON file and convert to powershell object

function jcat {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string] $Path
    )

    process {
        try {
            # that's it! that's the whole function! :D
            return (ConvertFrom-Json (cat -raw $Path) -Depth 20)
        } catch {
            if (-not ($_.Exception.Message -match 'Additional text')) { throw }

            if ((cat -raw $Path) -notmatch '^{.*}\s*$') {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"File contents not contained within braces."),
                        'jcat.MissingOutsideBraces',
                        [System.Management.Automation.ErrorCategory]::InvalidData,
                        $Path
                    )
                )
            }
        }
    }
}
