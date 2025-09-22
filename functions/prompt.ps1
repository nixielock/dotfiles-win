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
            $pwsh_pColor = $ansi_bryellow
            $pwsh_pMode = "admin"
            break
        }
        # connected to EXO
        { $pwsh_exoActive } {
            $pwsh_pColor = $ansi_brcyan
            $pwsh_pMode = "exo"
            break
        }
        # connected to on-prem
        { $pwsh_opexActive } {
            $pwsh_pColor = $ansi_cyan
            $pwsh_pMode = "opex"
            break
        }
        # connected to graph
        { $pwsh_graphActive } {
            $pwsh_pColor = $ansi_brgreen
            $pwsh_pMode = "graph"
            break
        }
        # none of the above
        default {
            $pwsh_pColor = $ansi_brblack
            $pwsh_pMode = "pwsh"
        }
    }

    # write ISO date and vertical bar (and wraparound bar!)
    [Console]::Write(@(
        "${ansi_red}//",
        "${ansi_brblack} $(zdate -Divider '' -Pad)T",
        "${ansi_white}$(ztime -Divider '' -PadHours)${dGray}z",
        "${ansi_red} | ${ansi_reset}"
    ) -join '')

    # show entire filepath if just changed
    $pwsh_currentPath = $PWD.Path
    if ($pwsh_currentPath -ne $script:pwsh_previousPath) {
        $script:pwsh_previousPath = $pwsh_currentPath

        $parsedPath = $pwsh_currentPath.Replace("$pwsh_home","~")
        [Console]::Write("${ansi_brwhite}$parsedPath")

    # otherwise, show only the current folder
    } else {
        $parsedPath = $pwsh_currentPath.Replace("$pwsh_home","~")

        # show in dark cyan if the path is the $pwsh_mainPath
        if ($pwsh_currentPath -like "$pwsh_mainPath*") {
            [Console]::Write("${ansi_cyan}$(@($parsedPath.Split('\'))[-1])")

        } else {
            [Console]::Write("${ansi_white}$(@($parsedPath.Split('\'))[-1])")
        }
    }

    # show git output if inside a git repo
    if ($toplevel = (git rev-parse --show-toplevel 2>$null)) {
        $reponame = $toplevel -replace ('.*/','')
        $repobranch = (git branch --show-current 2>$null)
        
        [Console]::WriteLine("${ansi_brcyan} | ${ansi_reset}$reponame/${ansi_brwhite}$repobranch${ansi_reset}")
    } else {
        [Console]::WriteLine("${ansi_reset}")
    }

    # print second line
    wr "[$pwsh_viModeSection] " -f $pwsh_viModeColor -n
    [Console]::Write("$pwsh_pColor$pwsh_pMode${ansi_brwhite} ")
    wr "⟩" -n

    # return final space for function to successfully override prompt
    return "${ansi_reset} "
}
