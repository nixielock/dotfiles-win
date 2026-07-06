# ---- drop - drop yanked item in working directory

function drop {
    param (
        [switch] $Clone
    )

    if (-not $pwsh_yanked) {
        ro "|@e|nothing held to drop!"
        return
    }

    if ($Clone) {
        cp $pwsh_yanked . -ea Stop
        ro "|@s|$($pwsh_yanked -replace '.*\\', '') cloned!"
    } else {
        mv $pwsh_yanked . -ea Stop
        ro "|@s|$($pwsh_yanked -replace '.*\\', '') dropped!"
        $global:pwsh_yanked = $null
    }
}
