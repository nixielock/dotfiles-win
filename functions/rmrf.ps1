# ---- rmrf - wrapper for Remove-Item -Recurse -Force

function rmrf {
    param(
        # path to delete
        [parameter(Position = 0)]
        [string] $Path,

        [switch] $Confirm
    )

    if ($Confirm) {
        $count = (gci $Path -recurse -ea Stop).Count + (gci $Path -recurse -hidden -ea Stop).Count
        ro "delete |@b|$count items|@|? |@d|[y/N] |@p|> " -n
        if ((Read-Host) -notmatch '[ya]') {
            return
        }
    }

    rm $Path -Recurse -Force -ea Stop
}
