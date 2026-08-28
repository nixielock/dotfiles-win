# ---- reparse - get target path item with all junctions replaced

function reparse {
    [CmdletBinding()]
    [OutputType([System.IO.FileSystemInfo])]
    param(
        # path with links
        [parameter(Position = 0, ValueFromPipeline)]
        [string] $Path = ".",

        # maximum recursion depth
        [parameter()]
        [int] $Depth = 4,

        [parameter()]
        [Alias('go', 'cd')]
        [switch] $ChangeDirectory
    )

    begin {
        $rpFilter = { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint }
    }

    process {
        $pathItem = (gi $Path -Force -ea Stop)

        if (-not ($pathItem |? $rpFilter)) {
            ro "|@w|path is not a reparse point!"
            return $pathItem.FullName
        }

        $par = $pathItem
        $reappend = ""
        $tries = 0
        :reparsing while ($tries -lt $Depth) {
            while (-not $par.Target) {
                if (-not $par.Parent) {
                    throw "No remaining parent of $($par.FullName) in directory tree"
                }
                if (-not ($par.Parent |? $rpFilter)) {
                    Write-Warning "base reparse point has no target (likely a cloud directory)"
                    $pathItem = gi ($par.FullName, $reappend -join "") -Force
                    break reparsing
                }

                # pull name of current level and then go up to parent
                $reappend = "\$($par.Name)", $reappend -join ""
                Write-Debug "Walking to parent $($par.Parent.Name)"
                $par = $par.Parent
            }

            # get target from current level of tree
            $target = (gi $par.Target -Force)
            Write-Debug "Item $($par.Name) has target path '$($target.FullName)'"
            if (-not ($target |? $rpFilter)) {
                $pathItem = gi ($target.FullName, $reappend -join "") -Force
                break reparsing
            }

            Write-Debug "'$($target.FullName)' is still a reparse point"

            # set parent for next run
            if (-not $target.Parent) {
                throw "No remaining parent of $($target.FullName) in directory tree"
            }
            if (-not ($target.Parent |? $rpFilter)) {
                Write-Warning "base reparse point has no target (likely a cloud directory)"
                $pathItem = gi ($target.FullName, $reappend -join "") -Force
                break reparsing
            }
            $reappend = "\$($target.Name)", $reappend -join ""
            $par = $target.Parent
            $target = $null
            $tries++
        }

        if ($tries -ge $Depth) {
            throw "Exceeded maximum reparsing depth of $Depth"
        }

        if ($ChangeDirectory) {
            cd $pathItem.FullName
        } else {
            return $pathItem
        }
    }
}
