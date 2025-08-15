# nav
# go to the path specified in l.nav (local or home)
# also display a comment if present

$pwsh_navFolder = "$env:USERPROFILE\.nav"

function nav {
    [CmdletBinding()]
    param (
        [parameter(Position=0, ValueFromPipeline)]
        [Alias('m')]
        [string] $Marker = 0,
        [Alias('l')]
        [switch] $List
    )

    if ($List) {
        $outList = @()
        (ls -path $pwsh_navFolder) |
            ? { $_.Extension -eq ".nav" } |
            % {
                $c = (cat $_.FullName -to 2)
                if ($c.Count -eq 1) {
                    $c = @($c)
                }
                $outList += [PSCustomObject]@{
                    Marker  = $_.Name -replace '\.nav$',''
                    Path    = "$($c[0])".Replace("$env:USERPROFILE\",'~\')
                    Comment = $c[1]
                }
            }
        $outList | Format-Table
        return
    }

    $navPath = "$pwsh_navFolder\$Marker.nav"
    $mText = " $Marker"

    try {
        $lnav = (cat $navPath -to 2 2>$null)
        
        switch ($lnav.Count -eq 1) {
            $true { $lnav = @($lnav); wr "nav " -n; wr "$Marker" -f green }
            $false { wr "nav $Marker`: "; wr "$($lnav[1])" -f green }
        }
        zd $lnav[0]

    } catch {
        wr "nav failed, marker $Marker.nav not set" -f red
    }
}

function setnav {
    [CmdletBinding()]
    param (
        [parameter(Position=0, ValueFromPipeline)]
        [Alias('m')]
        [string] $Marker = 0,
        [parameter(Position=1,ValueFromPipeline)]
        [Alias('c')]
        [string] $Comment
    )

    $navPath = "$pwsh_navFolder\$Marker.nav"

    try {
        if (!(Test-Path $navPath)) {
            ni $navPath | out-null
            wr "created $navPath" -f yellow
        }

        clc $navPath
        ac $navPath (gl)
        if ($Comment -match '\S') {
            $Comment -replace '\n',' '
            ac $navPath $Comment
        }

        wr "nav set!" -f green
    } catch {
        wr "setnav failed" -f e
        throw
    }
}
