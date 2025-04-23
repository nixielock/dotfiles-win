# ConvertTo-ScriptParameters
# load the function globally when script is called

function ConvertTo-ScriptParameters {
	[CmdletBinding()]
    [Alias('scriptsplat')]
    param (
        # literal string to convert to splatted parameters
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [string] $ParameterBlock,

        # path to script
        [parameter(Position=1, ValueFromPipeline)]
        [string] $ScriptPath,

        # use variables named after the parameter as placeholders, as in Rundeck inline scripts
        [alias('nv')]
        [switch] $UseNamedVariables
    )

    ro "|@p|parsing parameter block..."

    $paramDetails = ($ParameterBlock | select-string '(?:\[)(?<pType>[\w\.\[\]]+)(?:\] *\$)(?<pName>\w+)' -all).matches

    $outputLiteral = @"
|@ yellow|`$scriptParams|@| = @{
"@
    # end here-string

    $paramList = @()

    foreach ($p in $paramDetails) {
        $paramName = $p.groups['pName'].value

        if ($UseNamedVariables) {
            $placeholder = "`$$paramName"
        } else {
            $placeholder = "#$($p.groups["pType"].value)"
        }

        $outputLiteral += @"

    |@b|$paramName|@| = $placeholder
"@
        # end here-string
    }

    if ($ScriptPath -match '\S') {
        $pathString = "|@b|`"$ScriptPath`""
    } else {
        $pathString = '"path\to\script.ps1"'
    }

    $outputLiteral += @"

}
. $pathString|@w| @scriptParams|@|
"@
    
    ro "|@s|done!"
    ($outputLiteral -replace '\|@[\w\ ]*\|', '') | clip
    ro "splatted invocation |@p|copied to clipboard!`n"

    $outputLiteral | ro
}
