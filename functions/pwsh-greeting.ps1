# pwsh-greeting
# load the function globally when script is called

function pwsh-greeting {
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [float] $Elapsed = 0.0,

        [Alias('c')]
        [switch] $Center,

        [Alias('u')]
        [switch] $ShiftCursor,

        [Alias('f')]
        [switch] $Fetch,

        [Alias('cr','r')]
        [switch] $Refresh
    )
    
    if ($ShiftCursor) {
        # push cursor back up to top of screen
        wr "$pwsh_esc[1F" -n
    }
    
    # output header
    if ($Refresh) {
        $msg = "✨ the spellbook is open - the ritual is renewed ✨"
    } else {
        $msg = "✨ spellbook opened - ritual performed in |@b|$([math]::Round($Elapsed,3)) |@|seconds ✨"
    }

    if ($Center) {
        # get console centre
        $consoleCentre = $Host.UI.RawUI.BufferSize.Width / 2
        $msgLength = ($msg -replace $pwsh_roFormatTag,'').Length
        $padding = ''.PadLeft($consoleCentre - [int]($msgLength / 2))
        wr "$padding" -n
    }    
    
    ro "$msg"
    
    # display fetch
    if ($NoFetch) {
        hyfetch --distro "Windows 7" -p lesbian
    }
}
