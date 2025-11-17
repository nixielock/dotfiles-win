# ---- junction - create a new junction

function junction {
    [CmdletBinding()]
    param(
        # location of new junction
        [parameter(Position = 0, Mandatory)]
        [string] $Path,

        # directory for junction to point to
        [parameter(Position = 1, Mandatory)]
        [string] $Target
    )

    process {
        $targetItem = (gi $Target -ea Stop)
        if (-not $targetItem.PSIsContainer) {
            throw "Target must be a directory"
        }
        ni -ItemType Junction -Path $Path -Value ($targetItem.FullName) -ea Stop
    }
}
