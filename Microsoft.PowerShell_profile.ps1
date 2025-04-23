# ---- DIAGNOSTICS ----

# measure profile build time
$profileTimer = [System.Diagnostics.Stopwatch]::StartNew()

# ---- GLOBALS ----
#region globals

# cheeky aliases
sal 's' Select-Object
sal 'wr' Write-Host
sal 'npp' 'C:\Program Files\Notepad++\notepad++.exe'
sal 'no' Out-Null
sal 'str' Out-String

# globals
$pwsh_home        = (gi "~").FullName
$pwsh_homeEsc     = $pwsh_home -replace '\\', '\\'
$pwsh_username    = $pwsh_home -replace '.*\\', ''
$pwsh_scriptpath  = "$pwsh_home\awldrive\powershell"
$pwsh_roFormatTag = '\|@[\w\ ]*\|'
$pwsh_esc         = [char]0x1b
$pwsh_datapath    = "$pwsh_scriptpath\data"

#endregion globals

# ---- SETUP ----
#region setup

# configure vi keys
$pwsh_viModeSection = 'I'
$pwsh_viModeColor = 'green'
$setPSReadLineOptionParams = @{
    EditMode = 'vi'
    ExtraPromptLineCount = 1
    ContinuationPrompt = ''
    # PromptText = " ⟩", "!⟩"
    ViModeIndicator = 'Script'
    ViModeChangeHandler = {
        param ($viMode)
        switch ($viMode) {
            'Command' {
                $pwsh_viModeSection = 'N'
                $pwsh_viModeColor = 'red'
                wr "$pwsh_esc[1 q" -n
            }
            default {
                $pwsh_viModeSection = 'I'
                $pwsh_viModeColor = 'green'
                wr "$pwsh_esc[5 q" -n
            }
        }

        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
}
Set-PSReadlineOption @setPSReadLineOptionParams

# set directory formatting
$PSStyle.FileInfo.Directory = "`e[107;30m"

#endregion setup

# ---- FUNCTIONS ----
#region functions

# dot-source functions
ls $pwsh_scriptpath\functions\*.ps1 |
    % {
        $name = $_.Name
        try {
            . $_.FullName
        } catch {
            wr "failed to load $name - issue on line $($_.InvocationInfo.ScriptLineNumber)" -f red
        }
    }

#endregion

# ---- EXTERNALS ----
#region externals

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module
Import-Module -Name Microsoft.WinGet.CommandNotFound -ea SilentlyContinue
#f45873b3-b655-43a6-b217-97c00aa0db58

#endregion

# ---- CUSTOMISATIONS ----
#region customisations

# set variables for prompt
$pwsh_previousPath = ""
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
    if ((gl).ToString() -ne $pwsh_previousPath) {
        $pwsh_previousPath = (gl).ToString()

        $parsedPath = $pwsh_previousPath.Replace("$pwsh_home","~")
        wr "$parsedPath" -f white -n

    # otherwise, show only the current folder
    } else {
        $parsedPath = $pwsh_previousPath.Replace("$pwsh_home","~")

        # show in dark cyan if the path is the $pwsh_scriptpath
        if ($pwsh_previousPath -like "$pwsh_scriptpath*") {
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
            $false { $repodir.Replace('.*/([^/]+)/\.git','$1') }
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

# change title
if ((ls $pwsh_datapath).Name -notcontains 'iteration-counter.txt') {
    ni $pwsh_datapath\iteration-counter.txt -val '0'
}
$iterationCount = [int](Get-Content -path $pwsh_datapath\iteration-counter.txt -totalcount 1)
$iterationCount++
Out-File -filepath $pwsh_datapath\iteration-counter.txt -inputobject $iterationCount

$host.ui.RawUI.WindowTitle = “spellbook open | pg. $(cndz $iterationCount)z”

#endregion

# ---- DIAGNOSTICS ----

# stop timer
$profileTimer.Stop()

# display greeting
pwsh-greeting $profileTimer.Elapsed.TotalSeconds

# cleanup profile variables
rv profileTimer, iterationCount
