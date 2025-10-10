function syu {
    # load disallow-list
    $disabledList = $null
    if (Test-Path "$pwsh_datapath\syu-disallow.txt") {
        $disabledList = cat "$pwsh_datapath\syu-disallow.txt"
    }
    
    # display current scope
    $scopetext = $pwsh_isAdmin ? 'as |@yellow|admin|@|' : 'in |@cyan|user scope|@|'
    ro "updating winget packages $scopetext..."
    
    # fetch packages to update
    $updates = Get-WingetPackage |? IsUpdateAvailable
    if ($null -ne $disabledList) {
        $updatesDisabled = $updates |? { $disabledList -contains $_.Id }
        $updates = $updates |? { $disabledList -notcontains $_.Id }
    }

    ro "|@b|$($updates.Count) |@|updates available:"
    foreach ($u in $updates) {
        ro "  - $($u.Id) |@w|$($u.InstalledVersion) |@|-> |@p|$($u.AvailableVersions[0])"
    }
    foreach ($d in $updatesDisabled) {
        ro "  - $($d.Id) |@w|$($d.InstalledVersion) |@|-> |@e|manually disabled, will not update"
    }

    if ($updates.Count -lt 1) {
        return
    }

    # prompt to continue
    wr "proceed with updates? [Y/n] " -n
    wr "> " -f cyan -n

    if ((Read-Host) -match 'n') {
        return
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

    wr "updating package list... " -n
    $installedIds = (Get-WinGetPackage |? Id -notmatch '^(MSIX|ARP)\\').Id
    $prevIds = cat "$pwsh_datapath\winget-pkglist.txt"
    $newIds = $installedIds |? { $prevIds -notcontains $_ }
    $removedIds = $prevIds |? { $installedIds -notcontains $_ }

    if (($newIds -match '\S') -or ($removedIds -match '\S')) {
        wr ""
        wr "changes found since last run:" -f cyan 
        foreach ($id in $newIds) {
            wr "  - $id -> " -n
            wr "installed" -f yellow
        }
        foreach ($id in $removedIds) {
            wr "  - $id -> " -n
            wr "removed" -f yellow
        }

        wr "writing changes... " -n
        $installedIds >"$pwsh_datapath\winget-pkglist.txt"
        wr "done" -f green
    } else {
        wr "no changes"
    }
}
