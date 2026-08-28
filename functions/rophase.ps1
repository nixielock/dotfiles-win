# rophase - print moonphase but prettier :)
function rophase {
    $phase = moonphase
    wr "$($phase.Icon)" -f White -n
    ro "  $($phase.Phase.ToLower()) |@d|($([math]::Round(($phase.Illuminated * 100), 1))%)"
}
