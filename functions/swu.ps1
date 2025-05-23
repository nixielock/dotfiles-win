# ---- swu - <description>

function swu {
    [CmdletBinding()]
    param(
        # ids to update
        [parameter(Position = 0)]
        [string[]] $Id
    )

    process {
        if (-not ($Id -match '\S')) {
            throw "no ids listed to update!"
        }

        # display current scope
        $scopetext = $pwsh_isAdmin ? 'as |@yellow|admin|@|' : 'in |@cyan|user scope|@|'
        ro "updating winget packages $scopetext..."
        
        # fetch packages to update
        $allUpdates = Get-WingetPackage |? IsUpdateAvailable 

        wr "checking input packages..."
        
        $updates = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($pkgId in $Id) {
            $matchingPkg = $allUpdates |
                ? { ($_.Id -match ([regex]::Escape($pkgId))) -or ($_.Name -match ([regex]::Escape($pkgId))) }
            if ($matchingPkg.Count -gt 1) {
                wr "multiple matches for input '$pkgId', please specify:" -f yellow
                $matchingPkg.Id |% { wr "  - $_" }
                continue
            }
            if ($matchingPkg.Count -lt 1) {
                wr "no matches for input '$pkgId'" -f red
                continue
            }
            $updates.Add($matchingPkg)
        }
    
        ro "updating |@b|$($updates.Count) |@|packages:"
        foreach ($u in $updates) {
            ro "  - $($u.Id) |@w|$($u.InstalledVersion) |@|-> |@p|$($u.AvailableVersions[0])"
        }
    
        # iterate over upgradable packages
        foreach ($pkg in $updates){
            # reset result
            $result = $null
            ro "updating |@white|$($pkg.Id) |@|- " -n
        
            # update and get result
            $result = Update-WingetPackage $pkg -ea Stop
            # display error and go to next package if status is not ok
            if ($null -eq $result) {
                wr "failed (no result returned)" -f red
                continue
            }
        
            if ($result.Status -ne 'Ok') {
                wr "failed: $($result.Status) ($($result.InstallerErrorCode)" -f red -n
                if ($result.ExtendedErrorCode) {
                    wr " - $($result.ExtendedErrorCode)" -f red -n
                }
                wr ")" -f red
                continue
            }
            # display updated if ok
            wr "updated" -f green -n
        
            # show any non-zero error codes
            if ($result.InstallerErrorCode -ne 0) {
                wr ", " -n
                wr "exit code $($result.InstallerErrorCode)" -f yellow -n
            }
        
            # show if update requires reboot
            if ($result.RebootRequired) {
                wr " (requires restart)" -n
            }
        
            # newline for next package
            wr ""
        }
    }
}
