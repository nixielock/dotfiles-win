# ---- wipe-line - <description>

function wipe-line {
    param(
        # number of lines to wipe
        [parameter(Position = 0)]
        [int] $Lines = 0,

        # don't wipe current line
        [switch] $SkipCurrent
    )

    # set escape character
    $esc = [char]0x1b
    
    # wipe current line and reset cursor position
    if (!$SkipCurrent) {
        wr "$esc[2K$esc[0G" -n
    }
    
    # wipe lines above
    for ($i = 0; $i -lt $Lines; $i++) {
        wr "$esc[1F$esc[2K" -n
    }
}
