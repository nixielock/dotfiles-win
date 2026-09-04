function breakmode {
    if ($global:pwsh_pBreak) {
        $global:pwsh_pBreak = $false
        Set-PSReadLineOption -ExtraPromptLineCount 2
    } else {
        $global:pwsh_pBreak = $true
        Set-PSReadLineOption -ExtraPromptLineCount 1
    }
    $status = $global:pwsh_pBreak ? "|@s|enabled" : "|@w|disabled" #"
    ro "extra prompt linebreak $status"
}
