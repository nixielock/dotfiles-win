# Select-NotEmpty | ?ne
# only returns non-null or empty objects in pipe
function Select-NotEmpty {
    [CmdletBinding()]
    [Alias('?ne')]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        $InputObject,

        [parameter()]
        [string] $Property = ""
    )

    begin { $output = [System.Collections.Generic.List[PSObject]]::new() }

    process {
        if ($Property -ne "") {
            # filter by property
            $InputObject |
                ? { $_."$Property" -match '\S' } |
                % { $output.Add($_) }
            
        } else {
            # filter piped objects directly
            $InputObject |
                ? { $_ -match '\S' } |
                % { $output.Add($_) }
        }
    }

    end { $output }
}
