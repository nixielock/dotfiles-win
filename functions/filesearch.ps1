function filesearch {
    param (
        [parameter(Position = 0, Mandatory)]
        [string] $Pattern,

        [Alias('q')]
        [switch] $Quiet
    )

    # set cwd
    $wd = $PWD.Path
    
    # get all files
    $allFiles = gci -Recurse -attr !directory |? FullName -notmatch '\\\.git(\\|$)'

    # narrow down to only tracked files
    if ((gci -attr !directory).Name -contains '.gitignore') {
        $ignored = (cat .\.gitignore) -replace '/','\'
        $ignoredRegex = $ignored |% { "^", [Regex]::Escape(($_ -replace '\\$', '')), "(\\.*)?" -join '' }
        $script:ignoreOutput = @()
        
        $trackedFiles = $allFiles |
            % {
                # ignore files included in .gitignore
                $relPath = ($_.FullName.Replace("$wd\",''))
                $skip = ($relPath -in $ignored)                
                
                if (!$skip) {
                    foreach ($entry in $ignoredRegex) {
                        if ($relPath -match $entry) {
                            $skip = $true
                            break
                        }
                    }
                }
                
                if ($skip) {
                    $script:ignoreOutput += $relPath
                } else {
                    $_
                }
            }
        if (!$Quiet -and $script:ignoreOutput) {
            wr "ignoring:" -f yellow
            if ($script:ignoreOutput.Count -le 5) {
                $script:ignoreOutput |% { wr "  $_" -f yellow }
            } else {
                $script:ignoreOutput[0..4] |% { wr "  $_" -f yellow }
                wr "  (... $($script:ignoreOutput.Count - 5) more)" -f yellow
            }
        }
        rv ignoreOutput -Scope Script

    } else {
        $trackedFiles = $allFiles
    }
    
    # search tracked files for seach pattern
    foreach ($file in $trackedFiles) {
        $content = (cat $file)
        $relPath = ($file.FullName.Replace("$wd",'.'))
        $matchingLines = [System.Collections.Generic.List[string]]::new()
        
        $linecount = 0
        foreach ($line in $content) {
            $linecount++
            if ($line -imatch $Pattern) {
                $matchText = "$($matches[0])"
                $escText = (ro-escape $matchText)
                $replacedLine = [regex]::Replace((ro-escape $line), $escText, ("|@e|$escText|@d|"))
                $linenum = "$linecount".PadLeft(3)
                $matchingLines.Add("|@p|$linenum| |@d|$replacedLine")
            }
        }
        
        if ($matchingLines.Count -ge 1) {
            ro "|@b|$relPath |@d|- |@red|found matches:"
            $matchingLines | ro -e
            wr ""
            
        } elseif (!$Quiet) {
            ro "|@d|$relPath - |@s|no matches"
        }
    }
}
