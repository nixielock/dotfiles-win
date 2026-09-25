function breakmode {
    $global:pwsh_pBreak = !$global:pwsh_pBreak
    $extraLines = 1 + $global:pwsh_pBreak - $global:pwsh_pDemo
    Set-PSReadLineOption -ExtraPromptLineCount $extraLines
    $status = $global:pwsh_pBreak ? "|@s|enabled" : "|@w|disabled" #"
    ro "extra prompt linebreak $status"
}
