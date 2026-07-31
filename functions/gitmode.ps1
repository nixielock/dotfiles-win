function gitmode {
    $global:pwsh_pGit = !$global:pwsh_pGit
    $status = $global:pwsh_pGit ? "|@s|enabled" : "|@w|disabled" #"
    ro "git prompt $status"
}
