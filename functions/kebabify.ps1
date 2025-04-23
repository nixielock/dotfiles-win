# ---- kebabify
# renames all files in a folder to kebab-case
function kebabify {
    [CmdletBinding()]
    param (
        # folder to modify
        # leaving blank will use pwd
        [parameter(Position=0, ValueFromPipeline)]
        [string] $Directory = '.'
    )

    foreach ($filename in (ls $Directory -attr !directory).Name) {
        wr "$filename -> " -n
        # -- generate new name
        $newName = ($filename -creplace '([a-z])(?=[A-Z])|([A-Z])(?=[A-Z][a-z])','$1$2-').toLower()
        $newName = $newName -replace '[ _]','-'
        $newName = $newName -replace '---|\.(?=[^\.]*\.)','-'
        
        # skip if no changes would be made
        if ($newName -eq $filename) {
            wr "already kebab-case!" -f white
            continue
        }
        
        # otherwise, change to new name
        try {
            rni $Directory\$filename $newName -ea Stop
            wr "$newName" -f green
        } catch {
            wr "failed to change filename to $newName" -f red
        }
    }
}
