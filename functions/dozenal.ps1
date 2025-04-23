# dozenal.ps1
# contains various functions for conversion between base-10 and base-12 numbers, as well as a time and a date function
# uses the suffix d for decimal and z for dozenal
# uses X for 10d and H for 11d by default, but accepts other sets in $GlyphRecognitionSets
# you can change the output glyphs for 10d and 11d in $DozenalGlyphs too!

function Get-QuotientAndRemainder {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [int] $Numerator,

        [parameter(Mandatory=$true, Position=1, ValueFromPipeline)]
        [int] $Denominator
    )

    $remainderOut = $Numerator % $Denominator
    $quotientOut = ($Numerator - $remainderOut) / $Denominator

    return @{
        Quotient = $quotientOut
        Remainder = $remainderOut
    }
}

$DozenalGlyphs = @{
    0 = '0'
    1 = '1'
    2 = '2'
    3 = '3'
    4 = '4'
    5 = '5'
    6 = '6'
    7 = '7'
    8 = '8'
    9 = '9'
    10 = 'X'
    11 = 'H'
}

$GlyphRecognitionSets = @(
    @{  10 = 'A'
        11 = 'B' },

    @{  10 = 'D'
        11 = 'E' },

    @{  10 = 'T'
        11 = 'E' },

    @{  10 = 'X'
        11 = 'E' },

    @{  10 = 'X'
        11 = 'H' }
)

function Convert-DecimalToDozenal {
    [CmdletBinding()]
    [Alias('cndz')]
    param (
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [int] $Decimal,
        [switch] $Suffix
    )

    process {
        if ($Decimal -eq 0) {
            $glyphs = "0"

        } else {
            $negative = ($Decimal -lt 0)

            $valueInts = @()
            $decimalCountdown = $Decimal

            while ($decimalCountdown -ne 0) {
                $step = Get-QuotientAndRemainder -Numerator $decimalCountdown -Denominator 12
                $valueInts += $step.Remainder
                $decimalCountdown = $step.Quotient
            }

            # initialise empty string to avoid creating array
            $glyphs = ""

            # iterate backwards through $valueInts
            for ($i = $valueInts.Length - 1; $i -ge 0; $i--) {
                $glyphs += $DozenalGlyphs[[Math]::Abs($valueInts[$i])]
            }

            if ($negative) { $glyphs = "-$glyphs" }
        }

        if ($Suffix) { $glyphs = "${glyphs}z" }

        return $glyphs
    }
}

function Convert-DozenalToDecimal {
    [CmdletBinding()]
    [Alias('cnzd')]
    param (
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [string] $Dozenal
    )

    process {
        # remove any errant z markings
        $zParsed = $Dozenal -replace '[,z\s]',''

        if ($zParsed -like "-*") {
            $zParsed = $zParsed -replace '-',''
            $negative = $true
        }

        foreach ($set in $GlyphRecognitionSets) {
            $setRegex = "^[0-9$($set[10], $set[11] -join '')]+$"

            if (-not ($zParsed -notmatch $setRegex)) {
                $setUsed = $set
                break
            }
        }

        if (!$setUsed) {
            throw [System.ArithmeticException]::new(
                "The string $Dozenal could not be converted to a decimal integer. Please use a valid dozenal number format."
            )
        }

        $processArray = $zParsed -split '' |? { $_ }
        [array]::Reverse($processArray)

        $multiplier = 1
        $decimalTotal = 0

        foreach ($digit in $processArray) {
            switch ($digit) {
                $setUsed[10] { $val = 10 }
                $setUsed[11] { $val = 11 }
                default { $val = [int]$digit }
            }

            $decimalTotal += $val * $multiplier
            $multiplier *= 12
        }

        if ($negative) { $decimalTotal *= -1 }

        return $decimalTotal
    }
}

function Get-DozenalTime {
    [CmdletBinding()]
    [Alias('ztime')]
    param (
        [string] $Divider = ":",
        [switch] $AmPm,
        [switch] $PadHours,
        [switch] $Suffix
    )

    $decTime = (Get-Date -Format "H:h:m:tt") -split ":"
    $timeHash = @{
        Hour = Convert-DecimalToDozenal $decTime[0]
        ShortHour = Convert-DecimalToDozenal $decTime[1]
        Minute = (Convert-DecimalToDozenal $decTime[2]).PadLeft(2,'0')
        Polarity = $decTime[3].ToLower()
    }

    if ($PadHours) {
        $timeHash.Hour = ($timeHash.Hour).PadLeft(2,'0')
        $timeHash.ShortHour = ($timeHash.ShortHour).PadLeft(2,'0')
    }

    if ($AmPm) {
        $timeOut = "$($timeHash.ShortHour)$Divider$($timeHash.Minute)$($timeHash.Polarity)"

    } else {
        $timeOut = "$($timeHash.Hour)$Divider$($timeHash.Minute)"
    }

    if ($Suffix) {
        $timeOut += 'z'
    }

    return $timeOut
}

function Get-DozenalDate {
    [CmdletBinding()]
    [Alias('zdate')]
    param (
        [string] $Divider = "-",
        [ValidateSet('ISO', 'AUS', 'AusGov', 'Verbose')]
        [string] $Format = 'ISO',
        [switch] $Pad
    )

    $decDate = (Get-Date -Format "yyyy:M:d:MMMM") -split ":"
    $dateHash = @{
        Year = Convert-DecimalToDozenal $decDate[0]
        Month = Convert-DecimalToDozenal $decDate[1]
        Day = Convert-DecimalToDozenal $decDate[2]
    }

    if ($Pad) {
        $dateHash.Year = ($dateHash.Year).PadLeft(4,'0')
        $dateHash.Month = ($dateHash.Month).PadLeft(2,'0')
        $dateHash.Day = ($dateHash.Day).PadLeft(2,'0')
    }

    switch ($Format) {
        'ISO' {
            $dateOut = @($dateHash.Year, $dateHash.Month, $dateHash.Day) -join $Divider
        }
        'AUS' {
            $dateOut = @($dateHash.Day, $dateHash.Month, $dateHash.Year) -join $Divider
        }
        'AusGov' {
            $dateOut = "$($dateHash.Day) $($decDate[3]) $($dateHash.Year)"
        }
        'Verbose' {
            throw [System.NotImplementedException]::new("verbose not yet implemented - requires alt english library")
        }
        default {
            throw [System.ArgumentOutOfRangeException]::new("invalid format - $Format")
        }
    }

    return $dateOut
}