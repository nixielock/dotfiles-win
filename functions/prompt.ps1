# ---- prompt - replace the default powershell prompt!

# set variables for prompt
$script:pwsh_previousPath = ""
$pwsh_pColor = ""
$pwsh_pMode = ""
$pwsh_isAdmin = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"

# define prompt function
function Prompt {
    # set colour and text for mode display
    switch ($null) {
        # running as admin
        { $pwsh_isAdmin } {
            $pwsh_pColor = "yellow"
            $pwsh_pMode = "admin"
            break
        }
        # connected to EXO
        { $pwsh_exoActive } {
            $pwsh_pColor = "cyan"
            $pwsh_pMode = "exo"
            break
        }
        # connected to on-prem
        { $pwsh_opexActive } {
            $pwsh_pColor = "darkcyan"
            $pwsh_pMode = "opex"
            break
        }
        # connected to graph
        { $pwsh_graphActive } {
            $pwsh_pColor = "green"
            $pwsh_pMode = "graph"
            break
        }
        # none of the above
        default {
            $pwsh_pColor = "darkgray"
            $pwsh_pMode = "pwsh"
        }
    }

    # write ISO date and vertical bar (and wraparound bar!)
    wr "//" -f darkred -n
    wr " $(zdate -Divider '' -Pad)T" -f darkgray -n
    wr "$(ztime -Divider '' -PadHours)" -f gray -n
    wr "z" -f darkgray -n
    wr " | " -f darkred -n

    # show entire filepath if just changed
    $pwsh_currentPath = (gl).ToString()
    if ($pwsh_currentPath -ne $script:pwsh_previousPath) {
        $script:pwsh_previousPath = $pwsh_currentPath

        $parsedPath = $pwsh_currentPath.Replace("$pwsh_home","~")
        wr "$parsedPath" -f white -n

    # otherwise, show only the current folder
    } else {
        $parsedPath = $pwsh_currentPath.Replace("$pwsh_home","~")

        # show in dark cyan if the path is the $pwsh_mainPath
        if ($pwsh_currentPath -like "$pwsh_mainPath*") {
            wr "$(@($parsedPath.Split('\'))[-1])" -f darkcyan -n

        } else {
            wr "$(@($parsedPath.Split('\'))[-1])" -f gray -n
        }
    }

    # show git output if inside a git repo
    if ($repodir = (git rev-parse --git-dir 2>$null)) {
        $repobranch = (git branch --show-current 2>$null)

        $reponame = switch ($repodir -eq '.git') {
            $true { ($parsedPath.Split('\'))[-1] }
            $false { $repodir -replace ('.*/([^/]+)/\.git','$1') }
        }
        
        wr " | " -f cyan -n
        wr "$($reponame)/" -n
        wr "$($repobranch)" -f white
    } else {
        wr ""
    }

    # print second line
    wr "[$pwsh_viModeSection] " -f $pwsh_viModeColor -n
    # wr " : " -f darkgray -n
    wr "$pwsh_pMode" -f $pwsh_pColor -n
    wr " ⟩" -f white -n

    # return final space for function to successfully override prompt
    return " "
}
