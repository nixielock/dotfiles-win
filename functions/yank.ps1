# ---- yank - save a target file/directory to drop elsewhere

$global:pwsh_yanked = ""

function yank {
    param(
        # path of thing to be yanked
        [parameter(Position = 0)]
        [string] $Path = ".\*",

        [Alias('Release','c','r')]
        [switch] $Clear
    )

    if ($Clear) {
        if ($pwsh_yanked) {
            $y = (gi $pwsh_yanked -ea Stop)
            $global:pwsh_yanked = $null
            if ($y.Count -gt 1) {
                ro "released $($y.Count) items!"
            } else {
                ro "$($y.Name) released!"
            }
        } else {
            $global:pwsh_yanked = $null # force null anyway
            ro "nothing held to release!"
        }
        return
    }

    if ($pwsh_yanked) {
        ro "- currently holding |@w|$pwsh_yanked"
    }

    if ($Path -eq '.\*') {
        $items = (gci)
        if ($items.Count -eq 0) {
            ro "|@e|nothing to yank!"
            return
        }
        ro "yank all $($items.Count) items in working directory? [y/N] |@p|> " -n
        if ((Read-Host) -notmatch 'y') {
            return
        }
        $global:pwsh_yanked = "$PWD\*"
        ro "|@s|$($items.Count) items yanked!"
        return
    }

    $target = (gi $Path -ea Stop)
    $global:pwsh_yanked = $target.FullName
    ro "|@s|$($target.Name) yanked!"
}
