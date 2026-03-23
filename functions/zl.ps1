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
        [parameter(Position = 0, ValueFromPipeline)]
        [string] $Path = '.',

        [Alias('x')]
        [string] $ExcludePattern,
        
        [Alias('a')]
        [switch] $All,

        [Alias('l')]
        [switch] $LongFormat
    )

    begin {
        # repeatable function
        function print-item {
            [CmdletBinding()]
            param (
                [parameter(Position = 0, ValueFromPipeline)]
                [PSCustomObject] $Item
            )

            process {
                if ($useExclude -and ($Item.Category -match 'file') -and ($Item.Name -match $ExcludePattern)) {
                    $script:ignored++
                    return
                }
                if ($LongFormat) {
                    $modeFormat = $Item.Mode
                    $modeFormat = $modeFormat -replace '(?<!-)(-+)(?!-)', '|@d|$1|@b|'
                    $sizeFormat = $Item.Length
                    if ($Item.Category -match 'dir') {
                        $sizeFormat = "".PadLeft(6)
                    } elseif ($Item.Length -ge 1GB) {
                        $sizeFormat = $sizeFormat / 1GB
                        $sizeFormat = '{0:N1}' -f $sizeFormat
                        $sizeFormat = "|@dred|", "$sizeFormat".PadLeft(5), "G" -join ''
                    } elseif ($Item.Length -ge 1MB) {
                        $sizeFormat = $sizeFormat / 1MB
                        $sizeFormat = '{0:N1}' -f $sizeFormat
                        $sizeFormat = "|@dyellow|", "$sizeFormat".PadLeft(5), "M" -join ''
                    } elseif ($Item.Length -ge 1KB) {
                        $sizeFormat = $sizeFormat / 1KB
                        $sizeFormat = '{0:N1}' -f $sizeFormat
                        $sizeFormat = "|@|", "$sizeFormat".PadLeft(5), "K" -join ''
                    } else {
                        $sizeFormat = "|@d|", "$sizeFormat".PadLeft(6) -join ''
                    }
                    ro "|@b|$modeFormat|@| $sizeFormat  " -n
                }
                $c = $pwsh_zlCategories |? Name -eq $Item.Category
                wr ($c.Icon ?? '  ') -f $c.Color -n
                ro "|@$($c.Color)| $($Item.Name)" -n
                if ($Item.Target) {
                    ro "|@p| -> |@b|$($Item.Target.Replace($pwsh_home,'~'))" -n
                }
                [Console]::WriteLine()
            }
        }
        filter IsDirectory { if ($_.Category -match '[hg]?dir') { $_ } }
        filter IsVisibleFile { if ($_.Category -notmatch '[hg]?dir|[hg]file') { $_ } }
        filter IsHiddenFile { if ($_.Category -match '[hg]file') { $_ } }
    }

    process {
        # -- setup
        $pathItem = (gi $Path -ea Stop)
        if (-not $pathItem.PSIsContainer) {
            throw "$($pathItem.Name) is not a directory"
        }
        $shortPath = $pathItem.FullName.Replace("$env:USERPROFILE", "~")
        ro "|@b|`e[40m $shortPath "

        # pre-fetch list of hidden items
        $allItems = (ls $Path -Force)
        $hiddenItems = $allItems |? Mode -match 'h'

        # set whether hidden items are included
        if ($All) {
            $targetItems = $allItems
        } else {
            $targetItems = $allItems |? Mode -notmatch 'h'
            # show number of hidden items if not displaying all
            if ($hiddenItems.Count -ge 1) {
                ro "|@d|($($hiddenItems.Count) items hidden)"
            }
        }

        # init item list
        $itemList = [System.Collections.Generic.List[PSCustomObject]]::new()

        # init ignored counter
        $useExclude = ($null -ne $ExcludePattern) -and ($ExcludePattern -ne '')
        if ($useExclude) {
            $script:ignored = 0
        }

        # -- fetch items
    
        # populate item list
        foreach ($item in $targetItems) {
            # init variables
            $ctype = $null
            $name = $item.Name
            $hidden = ($name -match '^\.') -or ($item.Mode -match 'h')
        
            # > assign item type:
            # directories
            if ($item.PSIsContainer) {
                $ctype = $hidden ? 'hdir' : 'dir'
            }
            # pre-defined extensions
            $ctype ??= foreach ($c in ($pwsh_zlCategories |? Regex)) {
                if ($item.Extension -match $c.Regex) { $c.Name; break }
            }
            # remaining files
            $ctype ??= $hidden ? 'hfile' : 'file'
            # .git items
            if ($name -match '\.git') {
                $ctype = $ctype -replace 'h(file|dir)','g$1'
            }

            # > add item to list
            $itemList += [PSCustomObject]@{
                Name     = $name
                Category = $ctype
                Target   = $item.Target
                Length   = $item.Length
                Mode     = $item.Mode
            }
        }

        # -- output stages
    
        # directories and hidden directories
        $itemList | IsDirectory | sort Name | print-item
        # non-hidden files
        $itemList | IsVisibleFile | sort Name | print-item
        # hidden files
        $itemList | IsHiddenFile | sort Name | print-item
        # excluded
        if ($useExclude) {
            ro "|@d|($ignored items excluded)"
        }
    }
}

# "alias" function for -All and -LongFormat flags
function zla { zl -a }
function zll { zl -l }
