function filesearch {
    param (
        [parameter(Position = 0, Mandatory)]
        [string] $Pattern
    )

    # set cwd
    $wd = $PWD.Path
    
    # get all files
    $allFiles = (ls -Recurse -attr !directory)

    # narrow down to only tracked files
    if ((ls -attr !directory).Name -contains '.gitignore') {
        $ignored = (cat .\.gitignore) -replace '/','\'
        
        wr "ignoring:" -f yellow
        $trackedFiles = $allFiles |
            % {
                $relPath = ($_.FullName.Replace("$wd\",''))
                $skip = $false
                
                foreach ($i in $ignored) {
                    # ignore files included in .gitignore
                    if ($relPath -like $i -or $relPath -like "$i*") {
                        wr "  - $relPath" -f yellow
                        $skip = $true
                        break
                    }
                }
                
                if (!$skip) {
                    $_
                }
            }
    } else {
        $trackedFiles = $allFiles
    }

    $trackedFiles = $trackedFiles |? FullName -notmatch '\\\.git\\'
    
    # search tracked files for seach pattern
    foreach ($file in $trackedFiles) {
        $content = (cat $file)
        $relPath = ($file.FullName.Replace("$wd",'.'))
        $matchingLines = [System.Collections.Generic.List[string]]::new()
        
        $linecount = 0
        foreach ($line in $content) {
            $linecount++
            if ($line -imatch $Pattern) {
                $matchingLines += "|@p|$linecount. |@darkgray|" + [regex]::Replace($line, ($matches[0]), ("|@e|" + $matches[0] + "|@ darkgray|"))
            }
        }
        
        if ($matchingLines.Count -ge 1) {
            wr "$relPath " -f white -n
            wr "- " -f darkgray -n
            wr "found matches:" -f red
            $matchingLines | ro
            wr ""
            
        } else {
            wr "$relPath - " -f darkgray -n
            wr "no matches" -f green
        }
    }
}
