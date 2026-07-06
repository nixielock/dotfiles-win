# ahks

function ahks {
    [CmdletBinding()]
	param (
		[parameter(Position = 0, Mandatory)]
		[string] $HotString,
		[parameter(Position = 1, Mandatory)]
		[string] $Replacement
	)

	$replacementPath = "~\awldrive\.config\ahk\quick-replacements.ahk"
	$entry = "::#$HotString`::$Replacement"
    Add-Content -Path $replacementPath -Value $entry
	ro "|@s|added line to config: " -n
	wr "$entry" -f white
	& $replacementPath
}
