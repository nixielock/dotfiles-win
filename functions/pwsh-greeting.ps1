# pwsh-greeting

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
        [Alias('m','pom')]
        [switch] $MoonPhase,
        [Alias('cr','r')]
        [switch] $Refresh
    )
    
    if ($ShiftCursor) {
        # push cursor back up to top of screen
        wr "$pwsh_esc[1F" -n
    }
    
    # output header
    if ($Refresh) {
        $msgTop = " |@blue|spellbook open "
        $msgSub = " page |@b|0z$(cndz $global:pwsh_iterationCount)|@| "
    } else {
        $msgTop = " |@blue|spellbook opened "
        $msgSub = " ritual performed in |@b|$([math]::Round($Elapsed,3)) |@|seconds "
    }

    if ($Center) {
        # get console centre
        $consoleCentre = $Host.UI.RawUI.BufferSize.Width / 2
        $msgTopLen = ($msgTop -replace $pwsh_roFormatTag,'').Length
        $msgSubLen = ($msgSub -replace $pwsh_roFormatTag,'').Length
        $paddingTop = ''.PadLeft($consoleCentre - [int]($msgTopLen / 2) - 1)
        $paddingSub = ''.PadLeft($consoleCentre - [int]($msgSubLen / 2))
    } else {
        $paddingTop = ''
        $paddingSub = ''
    }

    wr "${paddingTop}✨" -n
    ro "$msgTop" -n
    wr "✨"
    ro "${paddingSub}$msgSub"
    
    # display fetch
    if ($Fetch) {
        # no more hyfetch :c
        # TODO: make my own fetch at some point!
        # windows logo art is saved in $pwsh_datapath\windows_ascii.txt
    }

    # moon phase
    if ($MoonPhase) {
        $phase = moonphase
        wr "  $($phase.Icon)" -f White -n
        ro "  $($phase.Phase.ToLower()) |@d|($([math]::Round(($phase.Illuminated * 100), 1))%)"
    }

    # display todo list
    # need to init $pwsh_todo before checking it (by running todo)
    todo
    if (-not $pwsh_todo) {
        [Console]::WriteLine()
    }
}
