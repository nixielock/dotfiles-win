# ---- DIAGNOSTICS ----

# measure profile build time
$profileTimer = [System.Diagnostics.Stopwatch]::StartNew()
$profileNoClear = $false

# ---- GLOBALS ----
#region globals

# cheeky aliases
sal 's' Select-Object
sal 'wr' Write-Host
sal 'no' Out-Null
sal 'str' Out-String
sal 'rand' Get-Random

wr "initialising... " -f darkgray -n

# > globals
# paths
$pwsh_home        = (gi "~").FullName
$pwsh_homeEsc     = $pwsh_home -replace '\\', '\\'
$pwsh_username    = $pwsh_home -replace '.*\\', ''
$pwsh_mainPath    = "$pwsh_home\awldrive\powershell"
$pwsh_datapath    = "$pwsh_mainPath\data\pwsh"
# helper vars
$pwsh_esc         = [char]0x1b
$pwsh_isAVDHost   = (hostname) -inotmatch '^avd.*'
$pwsh_ansi = @{
    'black' = "`e[30m"
    'red' = "`e[31m"
    'green' = "`e[32m"
    'yellow' = "`e[33m"
    'blue' = "`e[34m"
    'magenta' = "`e[35m"
    'cyan' = "`e[36m"
    'white' = "`e[37m"
    'brblack' = "`e[90m"
    'brred' = "`e[91m"
    'brgreen' = "`e[92m"
    'bryellow' = "`e[93m"
    'brblue' = "`e[94m"
    'brmagenta' = "`e[95m"
    'brcyan' = "`e[96m"
    'brwhite' = "`e[97m"
    'reset' = "`e[0m"
}
foreach ($key in $pwsh_ansi.Keys) {
    Set-Variable "ansi_$key" $pwsh_ansi[$key]
}
# environment vars
$env:EDITOR = 'hx'

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
    PromptText = "⟩ "
    ViModeIndicator = 'Script'
    ViModeChangeHandler = {
        param ($viMode)
        switch ($viMode) {
            'Command' {
                $pwsh_viModeSection = 'N'
                $pwsh_viModeColor = 'red'
                [Console]::Write("`e[1 q")
            }
            default {
                $pwsh_viModeSection = 'I'
                $pwsh_viModeColor = 'green'
                [Console]::Write("`e[5 q")
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

# dot-source functions
wr "- loading functions... " -f gray
ls $pwsh_mainPath\functions\*.ps1 |
    % {
        $name = $_.Name
        [Console]::Write("$($pwsh_ansi.brblack)  - $name -> ")
        try {
            . $_.FullName
            [Console]::WriteLine("$($pwsh_ansi.brgreen)loaded$($pwsh_ansi.reset)")
        } catch {
            $errLine = $_.InvocationInfo.ScriptLineNumber
            [Console]::WriteLine("$($pwsh_ansi.brred)failed - issue on line $errLine$($pwsh_ansi.reset)")
            $profileNoClear = $true
        }
    }

# dot-source unsynced (machine-specific) functions
if (Test-Path "$pwsh_mainPath\functions-unsynced") {
    wr "- loading unsynced functions... " -f gray
    ls $pwsh_mainPath\functions-unsynced\*.ps1 |
        % {
            $name = $_.Name
            [Console]::Write("$($pwsh_ansi.brblack)  - $name -> ")
            try {
                . $_.FullName
                [Console]::WriteLine("$($pwsh_ansi.brgreen)loaded$($pwsh_ansi.reset)")
            } catch {
                $errLine = $_.InvocationInfo.ScriptLineNumber
                [Console]::WriteLine("$($pwsh_ansi.brred)failed - issue on line $errLine$($pwsh_ansi.reset)")
                $profileNoClear = $true
            }
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
pwsh-greeting $profileTimer.Elapsed.TotalSeconds -f:$pwsh_isAVDHost -c

# cleanup profile variables
rv profileTimer, iterationCount, profileNoClear
