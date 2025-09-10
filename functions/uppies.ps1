# ---- uppies - show uptime!

function uppies {
    $uptime = (uptime)
    $hl = $pwsh_ansi.brwhite
    $rs = $pwsh_ansi.reset
    [Console]::WriteLine("machine $hl$(hostname)$rs has been up for $hl$($uptime.Days) days$rs, $hl$([math]::Round(($uptime.TotalHours % 24), 2)) hours$rs!")
}
