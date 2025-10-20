# ---- wipe-line - <description>

function wipe-line {
    param(
        # number of lines to wipe
        [parameter(Position = 0)]
        [int] $Lines = 0,

        # don't wipe current line
        [switch] $SkipCurrent
    )

    # wipe current line and reset cursor position
    if (!$SkipCurrent) {
        [Console]::Write("`e[2K`e[0G")
    }
    
    # wipe lines above
    for ($i = 0; $i -lt $Lines; $i++) {
        [Console]::Write("`e[1F`e[2K")
    }
}
