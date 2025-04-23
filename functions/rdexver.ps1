# rdexver
# load the function globally when script is called

function Get-RdexVersionName {
    [CmdletBinding()]
    [Alias('rdexver')]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [ValidateSet('Early','Mid','Late')]
        [string] $Series,

        [switch] $Major
    )

    begin {
        $dataPath = "~\data\gen"
        $planets = cat "$dataPath\minor-planets.txt"
        $colours = cat "$dataPath\ver-colours.txt"
        $used = cat "$dataPath\ver.txt"

        $esc = [char]0x1b
    }
    
    process {
        wr "fetching current version states... " -f darkgray -n
        $update = $used | % {
            $line = $_
            if ($line -imatch "${Series}_planet: (\d+)") {
                $planetNum = [int]"$($matches[1])"
                $p = $Major ? $planetNum : ($planetNum - 1)
                return ($line -replace ": \d+", ": $($p + 1)")
            }
            if ($line -imatch "${Series}_colour: (\d+)") {
                $colourNum = [int]"$($matches[1])"
                $c = $Major ? 0 : $colourNum
                return ($line -replace ": \d+", ($Major ? ": 0" : ": $($colourNum + 1)"))
            }
            return $line
        }

        wr "pulling name data... " -f gray -n
        $newPlanet = $planets[$p]
        $newColour = $colours[$c]
        wr "done!" -f green

        wr "updating version state... " -f darkgray -n
        set-content -path "$dataPath\ver.txt" -val $update -ea stop
        wr "done."

        wr ''
        wr "new version name (copied to clipboard!):"
        wr "$esc[3m$newPlanet $newColour$esc[0m" -f green
    }
}
