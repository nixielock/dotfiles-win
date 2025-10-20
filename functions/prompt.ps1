# ---- prompt - replace the default powershell prompt!

# set variables for prompt
$script:pwsh_previousPath = ""
$pwsh_pColor = ""
$pwsh_pMode = ""
$pwsh_isAdmin = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"

# define prompt function
function prompt {
    # set colour and text for mode display
    switch ($null) {
        # running as admin
        { $pwsh_isAdmin } {
            $pwsh_pColor = "|@w|"
            $pwsh_pMode = "admin"
            break
        }
        # connected to EXO
        { $pwsh_exoActive } {
            $pwsh_pColor = "|@p|"
            $pwsh_pMode = "exo"
            break
        }
        # connected to on-prem
        { $pwsh_opexActive } {
            $pwsh_pColor = "|@dcyan|"
            $pwsh_pMode = "opex"
            break
        }
        # connected to graph
        { $pwsh_graphActive } {
            $pwsh_pColor = "|@s|"
            $pwsh_pMode = "graph"
            break
        }
        # none of the above
        default {
            $pwsh_pColor = "|@dgray|"
            $pwsh_pMode = "pwsh"
        }
    }

    # write ISO date and vertical bar (and wraparound bar!)
    ro "|@dred|//|@dgray| $(zdate -div '' -pad)T|@|$(ztime -div '' -PadHours)${dGray}z|@dred| | " -n

    # show entire filepath if just changed
    $pwsh_currentPath = $PWD.Path
    if ($pwsh_currentPath -ne $script:pwsh_previousPath) {
        $script:pwsh_previousPath = $pwsh_currentPath

        $parsedPath = $pwsh_currentPath.Replace("$pwsh_home","~")
        ro "|@b|$parsedPath" -n

    # otherwise, show only the current folder
    } else {
        $endPath = $pwsh_currentPath -replace '.*\\([^\\]+)$', '$1'
        if ($pwsh_currentPath.Contains($env:USERPROFILE)) {
            $endPath = "|@dcyan|$endPath"
        }
        ro $endPath -n
    }

    # show git output if inside a git repo
    if ($toplevel = (git rev-parse --show-toplevel 2>$null)) {
        $reponame = $toplevel -replace ('.*/','')
        $repobranch = (git branch --show-current 2>$null)
        
        ro "|@p| | |@|$reponame/|@b|$repobranch" -n
    }
    [Console]::WriteLine()

    # print second line
    ro "|@$pwsh_viModeColor|[$pwsh_viModeSection] " -n
    ro "$pwsh_pColor$pwsh_pMode|@b| " -k -n
    wr "⟩" -n

    # return final space for function to successfully override prompt
    return "$ansi_reset "
}
