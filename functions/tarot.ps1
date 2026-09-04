# ---- tarot - open the labyrinthos definitions for selected tarot cards

sv pwsh_tarotSuits -Option ReadOnly -Value @("Swords", "Wands", "Pentacles", "Cups")
sv pwsh_tarotRanks -Option ReadOnly -Value @(
    "Ace",
    "Two",
    "Three",
    "Four",
    "Five",
    "Six",
    "Seven",
    "Eight",
    "Nine",
    "Ten",
    "Page",
    "Knight",
    "Queen",
    "King"
)
sv pwsh_tarotMajorArcana -Option ReadOnly -Value @(
    "0 The Fool",
    "I The Magician",
    "II The High Priestess",
    "III The Empress",
    "IV The Emperor",
    "V The Heirophant",
    "VI The Lovers",
    "VII The Chariot",
    "VIII Strength",
    "IX The Hermit",
    "X The Wheel of Fortune",
    "XI Justice",
    "XII The Hanged Man",
    "XIII Death",
    "XIV Temperance",
    "XV The Devil",
    "XVI The Tower",
    "XVII The Star",
    "XVIII The Moon",
    "XIX The Sun",
    "XX Judgement",
    "XXI The World"
)
$cards = $pwsh_tarotMajorArcana
foreach ($suit in $pwsh_tarotSuits) {
    foreach ($rank in $pwsh_tarotRanks) {
        $cards += "$rank of $suit"
    }
}
sv pwsh_tarotCards -Option ReadOnly -Value $cards
rv cards

function tarot {
    $majorList = $pwsh_tarotMajorArcana -replace '^[0IVX]+ (?:The )?', ''
    $majorUrl = "https://labyrinthos.co/blogs/tarot-card-meanings-list/<card_name>-meaning-major-arcana-tarot-card-meanings"
    $minorUrl = "https://labyrinthos.co/blogs/tarot-card-meanings-list/<card_name>-meaning-tarot-card-meanings"

    $cards = @()
    ro "i drew..."
    while ($true) {
        $index = $null
        ro "  |@p|> " -n
        $input = (Read-Host).ToLower() -replace 'the ', ''
        $reversed = $input -match 'r(eversed?)?$'
        $input = $input -replace ',? ?r(eversed?)?', ''
        if (-not $input) {
            wipe-line 1
            break
        }
        if ($majorList -icontains $input) {
            $index = $majorList.ToLower().IndexOf($input)
        } else {
            $minor = (($input -split ' ') -ne 'of') -match '\S'
            if ($minor.Count -ne 2) {
                throw "Unable to parse card input (incorrect number of terms)"
            }
            if ($minor[0] -match '^\d+$') {
                if ([int]($minor[0]) -gt 14) {
                    throw "Unable to parse card input (invalid rank '$($minor[0])')"
                }
                $rankIndex = $minor[0] - 1
            } else {
                $rankIndex = $pwsh_tarotRanks.ToLower().IndexOf(($minor[0]))
            }
            $suitIndex = $pwsh_tarotSuits.ToLower().IndexOf(($minor[1]))
            if ($rankIndex -eq (-1)) {
                throw "Unable to parse card input (invalid rank '$($minor[0])')"
            }
            if ($suitIndex -eq (-1)) {
                throw "Unable to parse card input (invalid suit '$($minor[1])')"
            }
            $index = $majorList.Count + ($suitIndex * $pwsh_tarotRanks.Count) + $rankIndex
        }
        $cards += $index
        wipe-line 1
        ro "  |@d|- |@b|$($pwsh_tarotCards[$index])" -n
        if ($reversed) {
            ro " (reversed)"
        } else {
            [Console]::WriteLine()
        }
    }
    foreach ($i in $cards) {
        $targetUrl = ""
        if ($i -lt $majorList.Count) {
            $urlCard = ($pwsh_tarotCards[$i] -replace '^[0IVX]+ ', '').ToLower() -replace ' ', '-'
            $targetUrl = $majorUrl -replace '<card_name>', $urlCard
        } else {
            $urlCard = $pwsh_tarotCards[$i].ToLower() -replace ' ', '-'
            $targetUrl = $minorUrl -replace '<card_name>', $urlCard
        }
        start $targetUrl
    }
    [Console]::WriteLine()
}
