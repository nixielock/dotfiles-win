# show git status if applicable
if ($repodir = (git rev-parse --git-dir 2>$null)) {
    $repobranch = (git branch --show-current 2>$null)
    return "|@blue| | |@|$($repodir)/|@b|$($repobranch)"
} else {
    return ""
}