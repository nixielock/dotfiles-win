# ---- prompt - replace the default powershell prompt!

# set variables for prompt
$script:pwsh_previousPath = ""
$pwsh_pColor = ""
$pwsh_pMode = ""
$pwsh_isAdmin = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"

$pwsh_ansi = @{
    'black' = "$pwsh_esc[30m"
    'red' = "$pwsh_esc[31m"
    'green' = "$pwsh_esc[32m"
    'yellow' = "$pwsh_esc[33m"
    'blue' = "$pwsh_esc[34m"
    'magenta' = "$pwsh_esc[35m"
    'cyan' = "$pwsh_esc[36m"
    'white' = "$pwsh_esc[37m"
    'brblack' = "$pwsh_esc[90m"
    'brred' = "$pwsh_esc[91m"
    'brgreen' = "$pwsh_esc[92m"
    'bryellow' = "$pwsh_esc[93m"
    'brblue' = "$pwsh_esc[94m"
    'brmagenta' = "$pwsh_esc[95m"
    'brcyan' = "$pwsh_esc[96m"
    'brwhite' = "$pwsh_esc[97m"
    'reset' = "$pwsh_esc[0m"
}

# define prompt function
function Prompt {
    # set colour and text for mode display
    switch ($null) {
        # running as admin
        { $pwsh_isAdmin } {
            $pwsh_pColor = $pwsh_ansi.bryellow
            $pwsh_pMode = "admin"
            break
        }
        # connected to EXO
        { $pwsh_exoActive } {
            $pwsh_pColor = $pwsh_ansi.brcyan
            $pwsh_pMode = "exo"
            break
        }
        # connected to on-prem
        { $pwsh_opexActive } {
            $pwsh_pColor = $pwsh_ansi.cyan
            $pwsh_pMode = "opex"
            break
        }
        # connected to graph
        { $pwsh_graphActive } {
            $pwsh_pColor = $pwsh_ansi.brgreen
            $pwsh_pMode = "graph"
            break
        }
        # none of the above
        default {
            $pwsh_pColor = $pwsh_ansi.brblack
            $pwsh_pMode = "pwsh"
        }
    }

    # set quick colours
    $reset = $pwsh_ansi.reset
    $dGray = $pwsh_ansi.brblack
    $lGray = $pwsh_ansi.white
    $white = $pwsh_ansi.brwhite
    $dRed = $pwsh_ansi.red
    $dCyan = $pwsh_ansi.cyan
    $lCyan = $pwsh_ansi.brcyan

    # write ISO date and vertical bar (and wraparound bar!)
    [Console]::Write(@(
        "$dRed//",
        "$dGray $(zdate -Divider '' -Pad)T",
        "$lGray$(ztime -Divider '' -PadHours)${dGray}z",
        "$dRed | $reset"
    ) -join '')

    # show entire filepath if just changed
    $pwsh_currentPath = $PWD.Path
    if ($pwsh_currentPath -ne $script:pwsh_previousPath) {
        $script:pwsh_previousPath = $pwsh_currentPath

        $parsedPath = $pwsh_currentPath.Replace("$pwsh_home","~")
        [Console]::Write("$white$parsedPath")

    # otherwise, show only the current folder
    } else {
        $parsedPath = $pwsh_currentPath.Replace("$pwsh_home","~")

        # show in dark cyan if the path is the $pwsh_mainPath
        if ($pwsh_currentPath -like "$pwsh_mainPath*") {
            [Console]::Write("$dCyan$(@($parsedPath.Split('\'))[-1])")

        } else {
            [Console]::Write("$lGray$(@($parsedPath.Split('\'))[-1])")
        }
    }

    # show git output if inside a git repo
    if ($toplevel = (git rev-parse --show-toplevel 2>$null)) {
        $reponame = $toplevel -replace ('.*/','')
        $repobranch = (git branch --show-current 2>$null)
        
        [Console]::WriteLine("$lCyan | $reset$($reponame)/$white$($repobranch)$reset")
    } else {
        [Console]::WriteLine("$reset")
    }

    # print second line
    wr "[$pwsh_viModeSection] " -f $pwsh_viModeColor -n
    [Console]::Write("$pwsh_pColor$pwsh_pMode$white ")
    wr "⟩" -n

    # return final space for function to successfully override prompt
    return "$reset "
}
