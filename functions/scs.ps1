# scs
# open today's screenshot folder
# !! note !! assumes you are sorting screenshots into subfolders like so: YYYY-MM\DD

# ---- global screenshot folder variable
# IMPORTANT: set your screenshot folder path here!
$global:pwsh_scFolder = "$pwsh_home\Pictures\Screenshots"

# ---- function proper
function scs {
    [CmdletBinding()]
    param(
        # open folder (default if no other options)
        [Alias('f')]
        [switch] $OpenFolder,
        
        # copy latest screenshot to clipboard
        [Alias('c')]
        [switch] $Copy,
        
        # open latest screenshot
        [Alias('o')]
        [switch] $OpenFile
    )

    # -- setup

    # set date and today's folder path
    $dateToday = (Get-Date)
    $date = $dateToday.ToString('yyyy-MM\\dd')
    $folderpath = "$pwsh_scFolder\$date"

    
    # open folder if no options selected
    if (-not ($OpenFolder -or $Copy -or $OpenFile)) {
        $OpenFolder = $true
    }

    # -- get latest screenshot folder

    # search for previous dates if folder doesn't exist
    wr "Checking for today's screenshot folder..." -n
    for ($offset = 1; (!(Test-Path $folderpath)); $offset++) {
        # output for first vs subsequent missing dates
        if ($offset -eq 1) {
            wr ""
            wr "$folderpath not found! Searching for most recent screenshot folder:" -f yellow

        } else {
            wr " not found."

            # throw if 4 weeks missing
            if ($offset -ge 28) {
                throw "No valid screenshot folder found in the past 4 weeks"
            }
        }
        
        # offset date, update folder
        $date = $dateToday.AddDays(-$offset).ToString('yyyy-MM\\dd')
        $folderpath = "$pwsh_scFolder\$date"

        wr "Checking " -n
        wr "$date..." -f white -n
    }
    wr " screenshot folder $date exists." -f green

    # -- operations
    
    # open latest located screenshot folder
    if ($OpenFolder) {
        wr "Opening screenshot folder " -n
        wr "$date... " -f white -n
        explorer $folderpath && wr "done!" -f green
    }

    # exit function if only opening folder
    if (-not ($Copy -or $OpenFile)) {
        return
    }
    
    # get latest screenshot for copy/open
    wr "Fetching latest file in screenshot folder " -n
    wr "$date" -f white -n
    wr "..." -n

    # fetch file with latest write time
    $screenshot = (ls $folderpath |? Extension -match '\.(pn|jpe?)g' | sort LastWriteTime)?[-1]
    
    # throw if no screenshots in latest folder
    if (!$screenshot) {
        wr "failed." -f red
        throw "No screenshots found in latest screenshot folder. Please delete the empty directory and try again."
    }
    
    wr "done!" -f green

    # set clipboard to screenshot
    if ($Copy) {
        wr "Copying image '$($screenshot.Name)' to clipboard... " -f cyan -n
        gi $screenshot.FullName | Set-Clipboard
        wr "done!" -f green
    }

    # open screenshot
    if ($OpenFile) {
        wr "Opening '$($screenshot.Name)'... " -n
        start $screenshot.FullName
        wr "done!" -f green
    }
}

function scs-clear {
    wr "removing screenshot folders older than 3 months!" -f yellow
    foreach ($folder in (ls $pwsh_scFolder |? LastWriteTime -lt ((Get-Date).AddMonths(-3)))) {
        wr "removing screenshots from $($folder.Name)... " -n
        Remove-Item $folder -Recurse -Force -Confirm:$false -ErrorAction Stop | Out-Null
        wr "done!" -f white
    }
}
