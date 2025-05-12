# ---- snippet - add a snippet to the big ol' json file in the snippets repo

$pwsh_snippetFile = "$pwsh_home\awldrive\repos\snippets\snippets.json"

function snippet {
    [CmdletBinding()]
    param(
        # name for the snippet
        [parameter(Position = 0)]
        [Alias('n')]
        [string] $Name,

        # contents of the snippet
        [parameter(Position = 1)]
        [Alias('c')]
        [string] $Content,

        [Alias('a')]
        [switch] $Add,
        
        [Alias('f')]
        [switch] $Force
    )

    begin {
        if ($null -eq (gi $pwsh_snippetFile -ea SilentlyContinue)) {
            throw "$pwsh_snippetFile not found"
        }
        
        $script:currentSnippets = [PSCustomObject[]](cat -raw $pwsh_snippetFile | ConvertFrom-Json -ea SilentlyContinue)
        if ($null -eq $script:currentSnippets) {
            if (!$Force) {
                throw "Could not convert $pwsh_snippetFile to JSON"
            }
            
            $script:currentSnippets = @()
        }
    }

    process {
        if (-not ($Add -xor ($script:currentSnippets.Name -contains $Name))) {
            throw [System.ArgumentException]::new(
                "Snippet $Name $($Add ? 'already exists' : 'does not exist')",
                "Name"
            )
        }

        if ($Add) {
            ro "adding new snippet |@b|$Name|@|... " -n
            $script:currentSnippets += [PSCustomObject]@{
                Name = "$Name"
                Content = "$Content"
                Date = "$(date -f "yyyy-MM-dd HH:mm:ss")"
            }
            wr "done" -f green
            
        } else {
            $snippet = ($script:currentSnippets |? Name -eq $Name)
            ro "|@p|snippet: |@b|$Name"
            ro "|@p|date: |@b|$($snippet.Date)"
            wr ""
            $snippet.Content | wr
            $snippet.Content | clip
            wr ""
            wr "copied to clipboard!" -f cyan
            wr ""
        }
    }

    end {
        if ($Add) {
            wr "writing changes to snippet file... " -n
            set-content $pwsh_snippetFile -val ($script:currentSnippets | ConvertTo-Json) -ea Stop
            wr "done" -f green
        }
    }
}
