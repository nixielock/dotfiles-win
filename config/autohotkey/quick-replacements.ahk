#Requires AutoHotkey v2.0

#Hotstring ? *

::#fn::{{}`n`n{}}{Up}{Tab}
::#fc::-ForegroundColor
::#bc::-BackgroundColor
::#nnl::-NoNewline
::#wr::Write-Host
::#isodd::{
	Send FormatTime(,"yyyy-MM-dd")
}
::#isond::{
	Send FormatTime(,"yyyyMMdd")
}
::#isosd::{
	Send FormatTime(,"yyyy/MM/dd")
}
::#isotd::{
	Send FormatTime(,"yyyyMMddTHHmmss")
}
::#cmdlet::[CmdletBinding()]
::#parstr::[parameter(Position = 0, ValueFromPipeline, Mandatory)]`n[string] $
::#ssc::/*  */{Left}{Left}{Left}
::#htc::<{!}--  -->{Left}{Left}{Left}{Left}
::#list::[System.Collections.Generic.List[]]{Left}{Left}
:k20:#hclip::{Esc}ggO@'{Esc}Go'@ | clip
