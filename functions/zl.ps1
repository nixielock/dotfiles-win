# zl
# named for zd - basically just fancy ls

# item categories and their associated regex
$pwsh_zlCategories = @(
    [PSCustomObject]@{
        Name  = 'code'
        Regex = "\.(md|(ht|x|ya|to)ml|css|json|ahk)"
        Color = 'white'
        Icon  = "`u{f121} "
    }
    [PSCustomObject]@{
        Name  = 'dir'
        Color = 'cyan'
        Icon  = "`u{f07b} "
    }
    [PSCustomObject]@{
        Name  = 'exe'
        Regex = "\.exe"
        Color = 'green'
    }
    [PSCustomObject]@{
        Name  = 'file'
        Color = 'gray'
    }
    [PSCustomObject]@{
        Name  = 'hdir'
        Color = 'darkcyan'
        Icon  = "`u{f114} "
    }
    [PSCustomObject]@{
        Name  = 'gdir'
        Color = 'darkcyan'
        Icon  = "`u{f0cd0} "
    }
    [PSCustomObject]@{
        Name  = 'hfile'
        Color = 'darkgray'
    }
    [PSCustomObject]@{
        Name  = 'gfile'
        Color = 'darkgray'
        Icon  = "`u{ea68} "
    }
    [PSCustomObject]@{
        Name  = 'img'
        Regex = "\.(png|jpe?g|gif)"
        Color = 'magenta'
        Icon  = "`u{f03e} "
    }
    [PSCustomObject]@{
        Name  = 'ps'
        Regex = "\.ps.?1"
        Color = 'blue'
        Icon  = "`u{e683} "
    }
    [PSCustomObject]@{
        Name  = 'zip'
        Regex = "\.(zip|rar|7z)"
        Color = 'yellow'
        Icon  = "`u{f410} "
    }
)

# function proper
function zl {
    [CmdletBinding()]
    [Alias('lz')]
    param (
        [Alias('a')]
        [switch] $All
    )

    # -- setup
    
    # write header
    Write-Host " $($pwd -replace "$pwsh_homeEsc","~")\ " -b white -f black -n
    Write-Host ""

    # pre-fetch list of hidden items
    $hiddenItems = (ls -Hidden)

    # show number of hidden items if not displaying all
    if (($hiddenItems.Count -ge 1) -and (!$All)) {
        wr "($($hiddenItems.Count) items hidden)" -f darkgray
    }

    # init item list
    $itemList = [System.Collections.Generic.List[PSCustomObject]]::new()

    # -- fetch items
    
    # populate item list
    foreach ($item in (ls)) {
        # init variables
        $ctype = $null
        $name = $item.Name
        $dotted = ($name -match '^\.')
        
        # > assign item type:
        
        # directories
        if ($item.PSIsContainer) {
            $ctype = switch ($dotted) {
                $true { 'hdir' }
                $false { 'dir' }
            }
        }

        # pre-defined extensions
        $ctype ??= foreach ($c in ($pwsh_zlCategories |? Regex)) {
            if ($item.Extension -match $c.Regex) {
                $c.Name
                break
            }
        }
        
        # remaining files
        $ctype ??= switch ($dotted) {
            $true { 'hfile' }
            $false { 'file' }
        }

        # .git items
        if ($name -match '\.git') {
            $ctype = $ctype -replace 'h(file|dir)','g$1'
        }

        # > add item to list
        $itemList += [PSCustomObject]@{
            Name     = $name
            Category = $ctype
            Target   = $item.Target
        }
    }

    # add hidden items to list
    if ($All) {
        foreach ($item in ($hiddenItems)) {
            $firstLetter = ($item.Name -match '\.git') ? 'g' : 'h'
            $itemList += [PSCustomObject]@{
                Name     = $item.Name
                Category = $firstLetter + (($item.PSIsContainer) ? 'dir' : 'file')
                Target   = $item.Target
            }
        }
    }

    # -- output stages
    
    # repeatable function
    function print-item {
        [CmdletBinding()]
        param (
            [parameter(Position = 0, ValueFromPipeline)]
            [PSCustomObject] $Item
        )

        process {
            $c = $pwsh_zlCategories |? Name -eq $Item.Category
            wr "$($c.Icon ?? "  ")" -f $c.Color -n
            wr " $($Item.Name)" -f $c.Color -n
            if ($Item.Target) {
                wr " -> " -f cyan -n
                wr "$($Item.Target.Replace($pwsh_home,'~'))" -f white -n
            }
            wr ""
        }
    }
    
    # directories and hidden directories
    $itemList | ? Category -match '[hg]?dir' | sort Name | print-item
    # non-hidden files
    $itemList | ? Category -notmatch '[hg]?dir|[hg]file' | sort Name | print-item
    # hidden files
    $itemList | ? Category -match '[hg]file' | sort Name | print-item
}

# "alias" function for -All flag
function zla { zl -a }
