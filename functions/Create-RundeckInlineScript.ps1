# Create-RundeckInlineScript
# load the function globally when script is called

function Create-RundeckInlineScript {
	[CmdletBinding()]
    param (
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [alias('name','n')]
        [string] $ScriptName,
        [parameter(Mandatory=$true, Position=1, ValueFromPipeline)]
        [alias('prefix','p')]
        [string[]] $CredentialPrefix,
        [parameter(Mandatory=$true, Position=2, ValueFromPipeline)]
        [alias('option','o')]
        [string] $RundeckOption
    )


}
