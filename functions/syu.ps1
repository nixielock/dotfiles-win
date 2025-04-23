function syu {
    # display current scope
    $scopetext = $pwsh_isAdmin ? 'as |@yellow|admin|@|' : 'in |@cyan|user scope|@|'
    ro "updating winget packages $scopetext..."
    
    # fetch packages to update
    $updates = Get-WingetPackage |? IsUpdateAvailable
    
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
