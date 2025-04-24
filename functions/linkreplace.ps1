# ---- linkreplace - for moving configs and other things into a centralised location!

$pwsh_linkDir = "~\awldrive\.config\symlinks"

function linkreplace {
    [CmdletBinding()]
    param (
        # name to give the new symlink in the register
        [parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Name,
        
        # path to the existing file/directory to be symlink-ified
        [parameter(Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Path
    )

    begin {
        if (!$pwsh_isAdmin) {
            throw "making symlinks requires admin!"
        }

        wr "initialising register..."
        $register = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
    
    process {
        wr ""
        ro "linking |@cyan|$Name!"
        ro "fetching |@white|$Path|@|... " -n
        $pathItem = (gi $Path -ea Stop)
        wr "done" -f green

        wr "checking link directory... " -n
        $isDirectory = $pathItem.PSIsContainer
        $newPath = switch ($isDirectory) {
            $true { "$pwsh_linkDir\$($pathItem.Name)" }
            $false { "$pwsh_linkDir\$Name\$($pathItem.Name)" }
        }

        if (!$isDirectory) {
            $existingDir = (gi "$pwsh_linkDir\$Name" -ea SilentlyContinue)
            if ($null -ne $existingDir) {
                if (-not ($existingDir.PSIsContainer)) {
                    wr ""
                    throw [System.ArgumentException]::new(
                        "$Name is an existing file - please choose a different name for the link directory.",
                        "Name"
                    )
                }
                wr ""
                wr "a directory named $Name already exists in $pwsh_linkDir" -f yellow
                wr "use the same directory? (y/N) " -n
                wr "> " -f cyan -n
                if ((Read-Host) -match 'y') {
                    ro "using |@white|$pwsh_linkDir\$Name|@|! " -n
                } else {
                    wr "linking cancelled, no changes made" -f yellow
                    return
                }
            } else {
                mkdir "$pwsh_linkDir\$Name" | Out-Null
                ro "created |@white|$pwsh_linkDir\$Name|@|! " -n
            }

            wr "finalising checks... " -n
        }
        
        if ($null -ne (gi $newPath -ea SilentlyContinue)) {
            throw [System.ArgumentException]::new(
                "$newPath already exists",
                "Path"
            )
        }

        wr "done" -f green

        ro "cloning $($isDirectory ? 'file' : 'directory') to |@white|$newPath|@|... " -n
        cp $pathItem $newPath -r:$isDirectory -ea Stop
        wr "done" -f green

        $sourceRename = "$($pathItem.Name).old-$(date -f 'yyyyMMddTHHmmss')"
        ro "renaming source to |@white|$sourceRename|@|... " -n
        rni $pathItem $sourceRename -ea Stop
        wr "done" -f green

        ro "creating $($isDirectory ? 'junction' : 'symlink') at |@white|$($pathItem.FullName)|@|... " -n
        $newItemParams = @{
            ItemType = ($isDirectory ? 'Junction' : 'SymbolicLink')
            Path = $pathItem.FullName
            Value = (gi $newPath).FullName
            ErrorAction = "Stop"
        }
        $newLink = ni @newItemParams
        wr "done" -f green
        ro "$($newLink.Name) |@cyan|-> |@white|$($newLink.Target)"

        ro "registering $($isDirectory ? 'junction' : 'symlink')... " -n
        $register += [PSCustomObject]@{
            Name        = $Name
            Target      = $newPath
            Path        = $pathItem.FullName
            IsDirectory = $IsDirectory
        }
        wr "done" -f green
    }

    end {
        ro "updating |@white|$pwsh_linkDir\register.csv|@|... " -n
        $register | Export-Csv "$pwsh_linkDir\register.csv" -Append
        wr "done" -f green
    }
}
