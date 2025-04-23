# renames all files in a folder to kebab-case
function Rename-AllToKebabCase {
    [CmdletBinding()]
    param (
        # folder to modify
        # leaving blank will use pwd
        [parameter(Position=0, ValueFromPipeline)]
        [string] $Directory = '.'
    )
    (ls $Directory -attr !directory).name |
        % {
            $newName = (($_ -creplace '([a-z])(?=[A-Z])|([A-Z])(?=[A-Z][a-z])','$1$2-').toLower() -replace '[ _]','-')
            $newName = $newName -replace '---|\.(?=[^\.]*\.)','-'
            if ($newName -eq $_) {
                write-host "$_ is already kebab-case!" -f green
            } else {
                try {
                    write-host "renaming $_ to $newName... " -n -ea stop
                    rni $Directory\$_ $newName -ea stop
                    write-host "done!" -f green
                } catch {
                    write-host "failed" -f red
                }
            }
        }
}

sal kebabify Rename-AllToKebabCase
