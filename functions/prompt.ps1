# ---- prompt - replace the default powershell prompt!

# set variables for prompt
$global:pwsh_pGit = $false
$global:pwsh_pBreak = $false
$script:pwsh_previousPath = ""
$pwsh_pColor = ""
$pwsh_pMode = ""
$pwsh_pLen = 0
$pwsh_isAdmin = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"

# define prompt function
function prompt {
    # set colour and text for mode display
    switch ($null) {
        # running as admin
        { $pwsh_isAdmin } {
            $pwsh_pColor = "|@w|"
            $pwsh_pMode = "admin"
            $pwsh_pLen = 12
            break
        }
        # connected to EXO
        { $pwsh_exoActive } {
            $pwsh_pColor = "|@p|"
            $pwsh_pMode = "exo"
            $pwsh_pLen = 10
            break
        }
        # connected to on-prem
        { $pwsh_opexActive } {
            $pwsh_pColor = "|@dcyan|"
            $pwsh_pMode = "opex"
            $pwsh_pLen = 11
            break
        }
        # connected to graph
        { $pwsh_graphActive } {
            $pwsh_pColor = "|@s|"
            $pwsh_pMode = "graph"
            $pwsh_pLen = 12
            break
        }
        # none of the above
        default {
            $pwsh_pColor = "|@d|"
            $pwsh_pMode = "pwsh"
            $pwsh_pLen = 11
        }
    }

    Set-PSReadlineOption -ContinuationPrompt "".PadLeft($pwsh_pLen)

    # add bonus linebreak before prompt
    if ($global:pwsh_pBreak) {
        [Console]::WriteLine()
    }

    # write ISO date and vertical bar (and wraparound bar!)
    $zDateTime = ztd -pad -dd '' -td ''
    ro "|@dred|//|@d| 0z|@|$($zDateTime.Date)|@d|-|@|$($zDateTime.Time)|@dred| | " -n

    # show entire filepath if just changed
    $pwsh_currentPath = $PWD.Path
    if ($pwsh_currentPath -ne $script:pwsh_previousPath) {
        $script:pwsh_previousPath = $pwsh_currentPath

        $parsedPath = $pwsh_currentPath.Replace("$env:USERPROFILE","~")
        ro "|@b|$parsedPath" -n

    # otherwise, show only the current folder
    } else {
        $endPath = $pwsh_currentPath.Replace("$env:USERPROFILE","~") -replace '.*\\([^\\]+)$', '$1'
        if ($pwsh_currentPath.Contains($env:USERPROFILE)) {
            $endPath = "|@dcyan|$endPath"
        }
        ro $endPath -n
    }

    # show git output if inside a git repo
    if ($pwsh_pGit) {
        if ($toplevel = (git rev-parse --show-toplevel 2>$null)) {
            $reponame = $toplevel -replace ('.*/','')
            $repobranch = (git branch --show-current 2>$null)
        
            ro "|@p| | |@|$reponame/|@b|$repobranch" -n
        }
    }
    [Console]::WriteLine()

    # print second line
    ro "|@$pwsh_viModeColor|[$pwsh_viModeSection] " -n
    ro "$pwsh_pColor$pwsh_pMode|@b| " -k -n
    wr "⟩" -n

    # return final space for function to successfully override prompt
    return "$ansi_reset "
}
