function dhms {
    [CmdletBinding()]
    [OutputType([timespan])]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [string] $InputObject
    )

    begin {
        $dhmsPattern = '^((?<d>\d+)d)? ?(?<h>\d+)h ?(?<m>\d+)m ?((?<s>\d+)s)?$'
    }

    process {
        $tstring = $InputObject.Trim()
        if ($tstring -match $dhmsPattern) {
            $d, $h, $m, $s = "$($matches.d)", "$($matches.h)", "$($matches.m)", "$($matches.s)"
            $timespan = [timespan]::Zero
            $timespan += (
                [timespan]::FromDays($d) +
                [timespan]::FromHours($h) +
                [timespan]::FromMinutes($m) +
                [timespan]::FromSeconds($s)
            )
            return $timespan
        } else {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ([System.ArgumentException]"Couldn't parse input string '$tstring'"),
                    'dhms.InvalidInputString',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $tstring
                )
            )
        }
    }
}

