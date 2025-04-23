function wgupdate {
    Get-WinGetPackage |? IsUpdateAvailable
}

function wgupgrade {
    wgupdate | Update-WinGetPackage -IncludeUnknown -Verbose
}
