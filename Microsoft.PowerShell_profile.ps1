# ---- DIAGNOSTICS ----

# measure profile build time
$profileTimer = [System.Diagnostics.Stopwatch]::StartNew()

# ---- GLOBALS ----
#region globals

$pwsh_username = ""

# cheeky aliases
sal 's' Select-Object
sal 'wr' Write-Host
sal 'npp' 'C:\Program Files\Notepad++\notepad++.exe'

# $pwsh_scriptpath - team scripts path
try {
    Set-Variable pwsh_scriptpath -option ReadOnly -value "C:\Users\$pwsh_username\code\pwsh" -ea Stop
} catch {
    Write-Host "Warning: Read-only variable `$pwsh_scriptpath not (re)set." -ForegroundColor Yellow
    Write-Host "Current value: $pwsh_scriptpath" -ForegroundColor DarkYellow
}

# $pwsh_roFormatTag - regex pattern for matching Write-RichOutput tags
try {
    Set-Variable pwsh_roFormatTag -option ReadOnly -value '\|@[\w\ ]*\|'
} catch {
    Write-Host "Warning: Read-only variable `$pwsh_roFormatTag not (re)set." -ForegroundColor Yellow
    Write-Host "Current value: $pwsh_roFormatTag" -ForegroundColor DarkYellow
}

$script:pwsh_operationCounter = 0
$script:pwsh_esc = [char]0x1b

#endregion globals

# ---- SETUP ----
#region setup

# Write-Safe
# parses ro-formatted text into Write-Host if ro isn't registered as a function
function Write-Safe {
    [CmdletBinding()]
    [Alias('wrs')]
    param ( 
        [parameter(Mandatory=$false, Position=0, ValueFromPipeline)]
        $message = "",
        
        [parameter(Mandatory=$false, Position=1, ValueFromPipeline)]
        [ValidateSet('Black','DarkBlue','DarkGreen','DarkCyan','DarkRed','DarkMagenta','DarkYellow',
            'Gray','DarkGray','Blue','Green','Cyan','Red','Magenta','Yellow','White')]
        $ForegroundColor = 'White',
        
        [Alias("nnl")]
        [switch] $NoNewline
    )

    if (!$pwsh_roFormatTag) {
        Set-Variable pwsh_roFormatTag -option ReadOnly -scope script -value '\|@[\w\ ]*\|'
    }

    try {
        ro $message -NoNewline:$NoNewline
    } catch {
        $message = $message -replace $pwsh_roFormatTag, ""
        Write-Host $message -ForegroundColor $ForegroundColor -NoNewline:$NoNewline
    }
}

# dot-source extended profile
. $pwsh_scriptpath\AWL-ISE-profile-ext.ps1
ls $pwsh_scriptpath\functions |
    ? { $_.Name -like "*.ps1" } |
    % {
        $fname = $_.Name
        try {
            . $_.FullName
        } catch {
            Write-Safe "|@e|failed to load $fname - issue on line $($_.InvocationInfo.ScriptLineNumber)"
        }
    }
. $pwsh_scriptpath\cosmetics\change-color.ps1

# configure vi keys
$viModeSection = 'I'
$setPSReadLineOptionParams = @{
    EditMode = 'vi'
    ExtraPromptLineCount = 1
    ViModeIndicator = 'Script'
    ViModeChangeHandler = {
        param ($viMode)

        switch ($viMode) {
            'Command' {
                $viModeSection = '|@ darkred|N'
                wr "$pwsh_esc[1 q" -n
            }
            default {
                $viModeSection = '|@ gray|I'
                wr "$pwsh_esc[5 q" -n
            }
        }

        $script:pwsh_operationCounter--
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
}
Set-PSReadlineOption @setPSReadLineOptionParams

# set directory formatting
$PSStyle.FileInfo.Directory = "`e[107;30m"

#endregion setup

# ---- FUNCTIONS ----
#region functions

# u...uuuuu / u1...u5
# use X number of 'u' or "uX" to cd up X steps
for ($i = 1; $i -le 5; $i++) {
  $u =  "".PadLeft($i,"u")
  $unum =  "u$i"
  $d =  $u.Replace("u","../")
  Invoke-Expression "function $u { set-location $d }"
  Invoke-Expression "function $unum { set-location $d }"
}

# uz...uuuuuz / u1z...u5z
# use X number of 'u' or "uX", followed by 'z', to zd up X steps
for ($i = 1; $i -le 5; $i++) {
  $u =  "".PadLeft($i,"u")
  $unum =  "u$i"
  $d =  $u.Replace("u","../")
  Invoke-Expression "function ${u}z { zd $d }"
  Invoke-Expression "function ${unum}z { zd $d }"
}

# mkcd
# create a new directory and set it as the current working directory
function mkcd {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [string] $Path
    )

    mkdir $Path
    cd $Path
    ro "Created directory |@ highlight|$(Get-Location) |@|and set to current location."
}

# lz
# named for zd - basically just fancy ls
function lz {
    [CmdletBinding()]
    [Alias('zl')]
    param ()
    
    Write-Host " $pwd\ " -b white -f black -n
    Write-Host ""
    foreach ($item in (ls)) {
        if ($item.PSIsContainer) { 
            ro "  |@ highlight|$($item.Name)" 
        } elseif ($item.Extension -like ".ps*1") { 
            ro "  |@ cyan|$($item.Name)"
        } else {
            ro "  $($item.Name)"
        }
    }
}

# zd (zork cd)
# literally just cd && lz
function zd {
    [CmdletBinding()]
    param (
        [parameter(Position=0, ValueFromPipeline)]
        [string] $Path = "C:\Users\$pwsh_username"
    )

    cd $Path
    lz
}

# Select-NotEmpty | ?>
# only returns non-null or empty objects in pipe
function Select-NotEmpty {
    [CmdletBinding()]
    [Alias('?>')]
    param (
        [parameter(Position=0, ValueFromPipeline)]
        $InputObject
    )

    begin {
        $outArray = @()
    }

    process {
        if ($InputObject -match '\S') {
            $outArray += $InputObject
        }
    }

    end {
        return $outArray
    }
}

# Open-CurrentScreenshotFolder / scs
# open today's screenshot folder
# !! note !! assumes you are sorting screenshots into subfolders like so: YYYY-MM\DD
function Open-CurrentScreenshotFolder {
    [CmdletBinding()]
    [Alias('scs')]
    param(
        [switch] $f, # open folder (default if no other options)
        [switch] $c, # copy latest screenshot to clipboard
        [switch] $o # open latest screenshot
    )

    # IMPORTANT: set your screenshot folder path here!
    $scFolder = "C:\Users\$pwsh_username\Pictures\Screenshots"
    $date = (Get-Date).ToString("yyyy-MM\\dd")

    $folderpath = "$scFolder\$date"

    if (!$f -and !$c -and !$o) { $f = $true }

    # search for previous dates if not found
    ro "Checking for today's screenshot folder..." -NoNewline

    for ($offset = 1 ; (!(Test-Path $folderpath)) ; $offset++) {
        if ($offset -eq 1) {
            $dne = $true
        
            Write-Safe "`n|@ warning|$folderpath not found! Searching for most recent screenshot folder:" -ForegroundColor Yellow

        } else { ro " not found." }

        $date = (Get-Date).AddDays(-$offset).ToString('yyyy-MM\\dd')
        $folderpath = "$scFolder\$date"

        if ($offset -ge 28) { throw "No valid screenshot folder found in the past 4 weeks" }
        else { ro "Checking |@ bright|$date..." -NoNewline }
    }

    Write-Safe "|@ success| screenshot folder $date exists." -ForegroundColor Green


    if ($f) {
        ro "Opening screenshot folder |@ bright|$date..." -NoNewline
        explorer $folderpath
        Write-Safe " |@ success|done!" -ForegroundColor Green
    }

    if ($c -or $o) {
        ro "Fetching latest file in screenshot folder |@ bright|$date|@|..." -NoNewline
        $screenshot = Get-ChildItem $folderpath | sort LastWriteTime | select -last 1

        if ($screenshot) {
            Write-Safe " |@ success|done!" -ForegroundColor Green

            if ($c) {
                Write-Safe "|@ prompt|Copying image `'$($screenshot.Name)`' to clipboard..." -ForegroundColor Cyan -NoNewline
                Get-ChildItem "$folderpath\$($screenshot.Name)" | Set-Clipboard
                Write-Safe " |@ success|done!" -ForegroundColor Green
            }

            if ($o) {
                ro "Opening |@ bright|`'$($screenshot.Name)`'|@|..." -NoNewline
                start "$folderpath\$($screenshot.Name)"
                Write-Safe " |@ success|done!" -ForegroundColor Green
            }

        } else {
            Write-Safe " |@ error|failed." -ForegroundColor Red
            Write-Safe "|@ warning|No screenshots found in latest screenshot folder. Please delete the empty directory and try again." -ForegroundColor Yellow
        }
    }
}

# Open-ProfileFunctions / pf
# open both profile and extended profile
function Open-ProfileFunctions {
    [CmdletBinding()]
    [Alias('pf')]
    param (
        [parameter(Position=0, ValueFromPipeline)]
        [string] $InputObject
    )

    if (!($InputObject -match '\S')) {
        hx $profile
    } else {
        
    }
}

#endregion

# ---- EXTERNALS ----
#region externals

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module
Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

# broot
. C:\Users\$pwsh_username\AppData\Roaming\dystroy\broot\config\launcher\powershell\br.ps1

#endregion

# ---- CUSTOMISATIONS ----
#region customisations

# prompt
$previousPath = ""
$isAdmin = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"
function Prompt {
    # replace home string with ~
    # yay linux vibes :)

    $pmc = "|@ white|"

    if ($isAdmin) {
        $pmc = "|@ yellow|"
    } elseif ($exoactive) {
        $pmc = "|@ cyan|"
    } elseif ($false) {
        $pmc = "|@ magenta|"
    }

    # write ISO date and vertical bar (and wraparound bar!)
    Write-Safe "$pmc┌|@ darkgray|$(zdate -Divider '' -Pad)|@ gray|$(ztime -Divider '' -PadHours)|@ darkgray|z|@ red| | " -ForegroundColor DarkRed -NoNewline

    # show entire filepath if just changed
    if ((Get-Location).ToString() -ne $previousPath) {
        $global:previousPath = (Get-Location).ToString()

        $parsedPath = $previousPath.Replace("C:\Users\$pwsh_username","~")
        ro "|@ white|$parsedPath" -NoNewline
    } else {
        $parsedPath = $previousPath.Replace("C:\Users\$pwsh_username","~")

        # show in dark cyan if the path is the $pwsh_scriptpath
        if ($previousPath -like "$pwsh_scriptpath*") {
            ro "|@ darkcyan|$(@($parsedPath.Split('\'))[-1])" -NoNewline

        } else {
            ro "|@ gray|$(@($parsedPath.Split('\'))[-1])" -NoNewline
        }
    }

    if ($repodir = (git rev-parse --git-dir 2>$null)) {
        $repobranch = (git branch --show-current 2>$null)

        $reponame = switch ($repodir -eq '.git') {
            $true { ($parsedPath.Split('\'))[-1] }
            $false { $repodir -replace '.*/([^/]+)/\.git','$1' }
        }
        
        ro "|@cyan| | |@|$($reponame)/|@b|$($repobranch)"
    } else {
        Write-Host ""
    }

    # print second line
    ro "$pmc└「$viModeSection|@ gray|:$((cndz $operationCounter).PadLeft(2,'0'))z$pmc」⟩" -NoNewline
    $script:pwsh_operationCounter++

    return " "
}

# change title

$iterationCount = [int](Get-Content -path $pwsh_scriptpath\iteration-counter.txt -totalcount 1)
$iterationCount++
Out-File -filepath $pwsh_scriptpath\iteration-counter.txt -inputobject $iterationCount

$host.ui.RawUI.WindowTitle = “spellbook open | pg. $(cndz $iterationCount)z”

#endregion

# ---- DIAGNOSTICS ----

$consoleCentre = $Host.UI.RawUI.BufferSize.Width / 2
$profileTimer.Stop()
wr "$([char]0x1b)[1F" -n
ro "$(''.PadLeft($consoleCentre - 28))✨ spellbook opened - ritual performed in |@b|$([math]::Round($profileTimer.Elapsed.TotalSeconds,3)) |@|seconds ✨"
Remove-Variable profileTimer
