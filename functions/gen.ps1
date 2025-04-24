# gen
# load the function globally when script is called

function Get-WordList {
    return (cat "$pwsh_mainPath\data\1000-wordlist-academic.txt")
}

function Get-AsciiSequence {
    [CmdletBinding()]
    param (
        
    )
}

function gen {
	[CmdletBinding()]
    param (
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [ValidateSet('email','words','alphanumeric','junk')]
        [string] $Pattern,
        [parameter(Mandatory=$true, Position=1, ValueFromPipeline)]
        [int] $Repeats,
        [parameter(Position=2, ValueFromPipeline)]
        [string] $Separator = ''
    )

    switch ($Pattern) {
        'words' {
            $words = (Get-WordList) | Get-Random -Count $Repeats
            if ($Separator) {
                return "$($words -join $Separator)"
            } else { return $words }
        }
        default { }
    }
}
