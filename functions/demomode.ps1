function demomode {
    $global:pwsh_pDemo = !$global:pwsh_pDemo
    $extraLines = 1 + $global:pwsh_pBreak - $global:pwsh_pDemo
    Set-PSReadLineOption -ExtraPromptLineCount $extraLines
    $status = $global:pwsh_pDemo ? "|@s|enabled" : "|@w|disabled" #"
    ro "demo prompt $status"
}
