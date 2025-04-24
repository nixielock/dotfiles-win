# ---- DIAGNOSTICS ----

# measure profile build time
$profileTimer = [System.Diagnostics.Stopwatch]::StartNew()
$profileNoClear = $false

# ---- GLOBALS ----
#region globals

# cheeky aliases
sal 's' Select-Object
sal 'wr' Write-Host
sal 'npp' 'C:\Program Files\Notepad++\notepad++.exe'
sal 'no' Out-Null
sal 'str' Out-String

wr "initialising... " -f darkgray -n

# globals
$pwsh_home        = (gi "~").FullName
$pwsh_homeEsc     = $pwsh_home -replace '\\', '\\'
$pwsh_username    = $pwsh_home -replace '.*\\', ''
$pwsh_mainPath    = "$pwsh_home\awldrive\powershell"
$pwsh_roFormatTag = '\|@[\w\ ]*\|'
$pwsh_esc         = [char]0x1b
$pwsh_datapath    = "$pwsh_mainPath\data"

wr "set -> " -f gray -n
wr "$($pwsh_mainPath.Replace($pwsh_home,'~'))" -f white

#endregion globals

# ---- SETUP ----
#region setup

wr "- configuring PSReadLine... " -f gray -n

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

wr "done" -f green

#endregion setup

# ---- FUNCTIONS ----
#region functions

wr "- loading functions... " -f gray

# dot-source functions
ls $pwsh_mainPath\functions\*.ps1 |
    % {
        $name = $_.Name
        wr "  - $name -> " -f darkgray -n
        try {
            . $_.FullName
            wr "loaded" -f green
        } catch {
            $errLine = $_.InvocationInfo.ScriptLineNumber
            wr "failed - issue on line $errLine" -f red
            $profileNoClear = $true
        }
    }

#endregion

# ---- EXTERNALS ----
#region externals

wr "- loading externals... " -f gray -n

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module
Import-Module -Name Microsoft.WinGet.CommandNotFound -ea SilentlyContinue
#f45873b3-b655-43a6-b217-97c00aa0db58

wr "done" -f green

#endregion

# ---- CUSTOMISATIONS ----
#region customisations

wr "- loading ui modificatons... " -f gray -n

# change title
if ((ls $pwsh_datapath).Name -notcontains 'iteration-counter.txt') {
    ni $pwsh_datapath\iteration-counter.txt -val '0'
}
$iterationCount = [int](Get-Content -path $pwsh_datapath\iteration-counter.txt -totalcount 1)
$iterationCount++
Out-File -filepath "$pwsh_datapath\iteration-counter.txt" -inputobject $iterationCount

$host.ui.RawUI.WindowTitle = "spellbook open | pg. $(cndz $iterationCount)z"

wr "done" -f green

#endregion

# ---- DIAGNOSTICS ----

# stop timer
$profileTimer.Stop()

if (!$profileNoClear) {
    clear
} else {
    wr ""
}

# display greeting
pwsh-greeting $profileTimer.Elapsed.TotalSeconds -f

# cleanup profile variables
rv profileTimer, iterationCount, profileNoClear
