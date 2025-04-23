# ahks
# load the function globally when script is called

function ahks {
    [CmdletBinding()]
	param (
		[parameter(Position = 0, Mandatory)]
		[string] $HotString,
		[parameter(Position = 1, Mandatory)]
		[string] $Replacement
	)
    # function body
	$entry = "::#$HotString`::$Replacement"
    Add-Content -Path "~\awldrive\.config\ahk\quick-replacements.ahk" -Value $entry
	ro "|@s|added line to config: |@ white|$entry"
}
