[System.Collections.Generic.List[string]] $script:pwsh_todo = ((cat "$pwsh_datapath\todo.txt") -as [string[]]) -match '\S'

function todo {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [string] $Add,

        [parameter()]
        $Remove
    )

    process {
        $script:pwsh_todo = ((cat "$pwsh_datapath\todo.txt") -as [string[]]) -match '\S'

        if ($null -ne $Remove) {
            try {
                $Remove = $Remove -as [int]
                if ($Remove -lt 0) {
                    $Remove = $script:pwsh_todo.Count + $Remove
                }
                ro "|@w|removing todo item:"
                $script:pwsh_todo[$Remove] | ro
                ro "updating list... " -n
                $newTodo = [System.Collections.Generic.List[string]]::new()
                for ($i = 0; $i -lt $script:pwsh_todo.Count; $i++) {
                    if ($i -ne $Remove) {
                        $newTodo.Add(($script:pwsh_todo[$i]))
                    }
                }
                $script:pwsh_todo.Clear()
                $script:pwsh_todo = $newTodo
                ro "|@b|writing... " -n
                $script:pwsh_todo >"$pwsh_datapath\todo.txt"
                ro "|@s|done"
            } catch {
                wr ""
                throw
            }
            return
        }

        if ($Add) {
            try {
                ro "adding as item |@p|$($script:pwsh_todo.Count)|@|... " -n
                $script:pwsh_todo.Add($Add)
                ro "|@b|writing... " -n
                $script:pwsh_todo >"$pwsh_datapath\todo.txt"
                ro "|@s|done"
            } catch {
                wr ""
                throw
            }
            return
        }

        # update todo list
        # display todo list
        if ($script:pwsh_todo) {
            $len = 0
            foreach ($l in ($script:pwsh_todo -replace $ro_tag, '')) {
                if ($l.Length -gt $len) {
                    $len = $l.Length
                }
            }
            wr ""
            ro "     |@d|- |@blue|++++ todo! ++++ |@d|-$(''.PadRight([math]::Max(($len - 18), 0), '-'))"
            $counter = 0
            $script:pwsh_todo |% { ro "|@d|$("$counter".PadLeft(3))`:|@| $_"; $counter++ }
            ro "     |@d|-------------------$(''.PadRight([math]::Max(($len - 18), 0), '-'))"
            wr ""
        }
    }
}
