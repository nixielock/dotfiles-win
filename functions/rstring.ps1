# ---- rstring - make random strings

function rstring {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        # 1 value == length of string(s)
        # 2 values == min and max length
        # 3+ values == allowed lengths
        [parameter(Position = 0)]
        [int[]] $Length = 16,

        # number of strings to generate
        [parameter(Position = 1)]
        [int] $Count = 1,

        # sets to allow
        [parameter()]
        [ValidateSet(
            'Lowercase',
            'Uppercase',
            'Numbers',
            'Alphanumeric',
            'Spaces',
            'WordCharacters',
            'SingleQuotes',
            'DoubleQuotes',
            'Special'
        )]
        [string[]] $Include = 'WordCharacters'
    )

    $charArrays = @{
        Lowercase      = [char[]](('a'..'z' -join '').ToCharArray())
        Uppercase      = [char[]](('A'..'Z' -join '').ToCharArray())
        Numbers        = [char[]](('0'..'9' -join '').ToCharArray())
        Spaces         = [char[]](' '.ToCharArray())
        SingleQuotes   = [char[]]("'".ToCharArray())
        DoubleQuotes   = [char[]]('"'.ToCharArray())
        Punctuation    = [char[]]('.,!?-;()'.ToCharArray())
    }
    $charArrays.Alphanumeric = [char[]]($charArrays.Lowercase + $charArrays.Uppercase + $charArrays.Numbers)
    $charArrays.WordCharacters = [char[]]($charArrays.Alphanumeric + '_'.ToCharArray())
    $charArrays.Special = [char[]]('!@#$%^&*()-_=+[]{}\|,<.>/?~;:'.ToCharArray())

    $allowedCharacters = [System.Collections.Generic.List[char]]::new()
    foreach ($set in $Include) {
        $allowedCharacters.AddRange($charArrays[$set])
    }
    $allowedCharacters = $allowedCharacters | Sort-Object | Get-Unique

    $output = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $Count; $i++) {
        $string = ""
        $len = switch ($Length.Count) {
            1 { $Length[0] }
            2 { (Get-Random -Min $Length[0] -Max $Length[1]) }
            default { ($Length | Get-Random) }
        }
        for ($j = 0; $j -lt $len; $j++) {
            $string += $allowedCharacters | Get-Random
        }
        $output.Add($string)
    }

    return $output
}
