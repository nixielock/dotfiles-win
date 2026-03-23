# ---- xpr - convert an object into a simple List<PSCustomObject> with the names and values of all its properties

function xpr {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[PSCustomObject]])]
    param(
        # object to extract properties from
        [parameter(Position = 0, ValueFromPipeline)]
        $InputObject
    )

    process {
        $properties = $InputObject.PSObject.Properties
        $outputList = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($p in $properties) {
            $outputList.Add([PSCustomObject]@{
                Name = $p.Name
                TypeDetails = (typecheck $p.Value -p).Description
                Value = $p.Value
            })
        }
        return $outputList
    }
}
