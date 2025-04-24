function ansi {
    [CmdletBinding()]
    param ()

    # ! TODO: fix this whole thing lmao
    throw [System.NotImplementedException]::new()

    $esc = [char]0x1b
    $seq = [System.Collections.Generic.List[string]]::new()
    $seq += "$esc["

    # ansi reset
    if (-not ($args -match "\S")) {
        $seq += "0m"
        return $seq -join ''
    }

    # parse by word
    if (-not ($args -match "[0-9]")) {
        
    }

    # parse as sequence entries
    if ($args.Count -eq ($args |? { $_ -match "^[0-9]{1,2}" }).Count) {
        
    }

    # parse as hex
    if ($args.Count -eq ($args |? { $_ -match "^#([0-9A-Fa-f]{3}|([0-9A-Fa-f]{6})" }).Count) {
        
    }
}
