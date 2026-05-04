# ---- ro - write ansi-formatted output using inline tags

if ($null -eq $ansi_reset) {
    $pwsh_ansi = @{
        'black' = "$([char]0x1b)[30m"
        'red' = "$([char]0x1b)[31m"
        'green' = "$([char]0x1b)[32m"
        'yellow' = "$([char]0x1b)[33m"
        'blue' = "$([char]0x1b)[34m"
        'magenta' = "$([char]0x1b)[35m"
        'cyan' = "$([char]0x1b)[36m"
        'white' = "$([char]0x1b)[37m"
        'brblack' = "$([char]0x1b)[90m"
        'brred' = "$([char]0x1b)[91m"
        'brgreen' = "$([char]0x1b)[92m"
        'bryellow' = "$([char]0x1b)[93m"
        'brblue' = "$([char]0x1b)[94m"
        'brmagenta' = "$([char]0x1b)[95m"
        'brcyan' = "$([char]0x1b)[96m"
        'brwhite' = "$([char]0x1b)[97m"
        'reset' = "$([char]0x1b)[0m"
    }
    foreach ($key in $pwsh_ansi.Keys) {
        Set-Variable "ansi_$key" $pwsh_ansi[$key]
    }
}

sv ro_captureTag '\|@\ ?(\w*)\ ?\|' -option ReadOnly
sv ro_tag '\|@\ ?\w*\ ?\|' -option ReadOnly

$ro_list = @{
    black = @('black')
    red = @('darkred','dred')
    green = @('darkgreen','dgreen')
    yellow = @('darkyellow','dyellow')
    blue = @('darkblue','dblue')
    magenta = @('darkmagenta','dmagenta')
    cyan = @('darkcyan','dcyan')
    white = @('gray')
    brblack = @('d','dim','darkgray','dgray')
    brred = @('e','error','red')
    brgreen = @('s','success','green')
    bryellow = @('w','warn','warning','yellow')
    brblue = @('blue')
    brmagenta = @('h','hl','highlight','magenta')
    brcyan = @('p','prompt','cyan')
    brwhite = @('b','bright','white')
}

$ro_keys = @{
    '' = $ansi_reset
}

foreach ($color in $ro_list.Keys) {
    foreach ($keyword in $ro_list[$color]) {
        [void]($ro_keys.Add($keyword, (gv "ansi_$color").Value))
    }
}

function ro {
    [CmdletBinding()]
    param(
        # input message to print
        [parameter(Position = 0, ValueFromPipeline)]
        [string] $InputObject = "",

        # print escaped ro tags as the original tag (without interpreting)
        [Alias('e')]
        [switch] $Escape,

        # same as Write-Host's NoNewline
        [Alias('n')]
        [switch] $NoNewline,

        # don't insert an ansi reset sequence at the end of the output
        [Alias('k')]
        [switch] $NoReset
    )

    process {
        # split input string into a section for each tag
        $splits = $InputObject -split "(?=$ro_tag)"
        # replace tags with corresponding ansi sequence
        $outSplits = foreach ($section in $splits) {
            $seq = $ro_keys[($section -replace "$ro_captureTag.*", '$1')]
            $section -replace $ro_tag, $seq
        }
        $outString = $outSplits -join ''

        # replace escaped ro tags with original tags
        if ($Escape) {
            $outString = $outString -replace '\|\\@(\w*)\|', '|@$1|'
        }

        # add reset sequence
        if (-not $NoReset) {
            $outString += $ansi_reset
        }

        # print resulting string
        if ($NoNewline) {
            [Console]::Write($outString)
        } else {
            [Console]::WriteLine($outString)
        }
    }
}

# ---- ro-escape - escape ro tags to display them with ro -e

function ro-escape {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [string] $InputObject
    )

    process {
        $InputObject -replace $ro_captureTag, '|\@$1|'
    }
}
