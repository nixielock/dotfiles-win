# ---- delcat - preview text files one by one and delete them

function delcat {
    param (
        # lines to preview for each item
        [int] $Preview = "20",

        [Alias('to')]
        [string] $MoveTo
    )

    $script:killcount = 0
    $noRm = (($null -ne $MoveTo) -and ($MoveTo -ne ''))
    if ($noRm) {
        try {
            $target = (gi $MoveTo -ea Stop)
            if (-not $target.PSIsContainer) {
                throw
            }
        } catch {
            throw [System.ArgumentException]::new(
                "Target location $MoveTo is not a directory",
                'MoveTo'
            )
        }
    }
    
    # display items one by one
    foreach ($item in (ls -attr !directory)) {
        $filename = $Item.Name
        
        # preview file contents
        try {
            $lines = cat $filename -TotalCount 1001
        } catch {
            wr "delcat couldn't access $filename!" -f red
            continue
        }
        
        # display linecount if greater than $Preview, otherwise remove fewer lines
        wr "$filename" -f white -n
        $printLines = $Preview
        switch ($lines.Count) {
            { $_ -gt 1000 } { wr " (>1000 lines)" -f gray; break }
            { $_ -gt $Preview } { wr " ($($lines.Count) lines)" -f darkgray; break }
            default { wr ""; $printLines = $lines.Count }
        }

        # display preview
        foreach ($l in ($lines | select -first $Preview)) {
            if ($l.Length -gt ($Host.UI.RawUI.BufferSize.Width -2)) {
                $l = $l.Substring(0,($Host.UI.RawUI.BufferSize.Width -2)) -replace '...$','...'
            }
            wr "  $l" -f darkgray
        }
        
        # present option to delete
        ro "|@b|delete? |@|(y/N) |@p|>|@| " -n
        if ((Read-Host) -match '[ya]') {
            if ($noRm) {
                mv $filename $MoveTo
                wipe-line ($printLines + 2)
                ro "|@b|$filename |@|-> |@w|moved"
                $script:killcount++
                continue
            } else {
                rm $filename
                wipe-line ($printLines + 2)
                ro "|@b|$filename |@|-> |@e|deleted"
                $script:killcount++
                continue
            }
        } else {
            wipe-line ($printLines + 2)
            ro "|@b|$filename |@|-> kept"
        }
    }
    
    wr "delcat $($noRm ? 'moved' : 'vanquished') $script:killcount files!" -f green
}
