# nav
# go to the path specified in l.nav (local or home)
# also display a comment if present

$pwsh_navFolder = "$env:USERPROFILE\.nav"

function nav {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [Alias('m')]
        [string] $Marker = 0,

        [Alias('l')]
        [switch] $List
    )

    # list .nav links and exit
    if ($List) {
        $fileList = gci -path $pwsh_navFolder -force -ea Stop
        $outList = @()
        foreach ($file in $fileList) {
            if ($file.Extension -eq '.nav') {
                $c = (cat $file.FullName -to 2)
                if ($c.Count -eq 1) {
                    $c = @($c)
                }
                $outList += [PSCustomObject]@{
                    Marker  = $file.BaseName
                    Path    = $c[0] -replace [regex]::Escape("$env:USERPROFILE\"), '~\'
                    Comment = $c[1]
                }
            }
        }
        return $outList
    }

    $navFile = "$pwsh_navFolder\$Marker.nav"
    try {
        $lnav = @() + (cat $navFile -to 2 -ea Stop)
        
        if ($lnav[1]) {
            ro "nav |@b|${Marker}|@|: |@s|$($lnav[1])"
        } else {
            ro "nav |@s|$Marker"
        }
        zd $lnav[0]

    } catch {
        wr "nav failed, marker $Marker.nav not set" -f red
        throw
    }
}

function setnav {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [Alias('m')]
        [string] $Marker = 0,

        [parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('c')]
        [string] $Comment,

        [parameter(ValueFromPipelineByPropertyName)]
        [string] $Target = $PWD.Path
    )

    $navFile = "$pwsh_navFolder\$Marker.nav"
    try {
        if (-not (Test-Path $navFile)) {
            [void] (ni $navFile)
            wr "created $navFile" -f yellow
        }

        Set-Content $navFile -Value $Target
        if ($Comment) {
            $Comment -replace '\n',' '
            Add-Content $navFile -Value $Comment
        }

        ro "|@s|nav set!"
    } catch {
        ro "|@e|setnav failed"
        throw
    }
}
