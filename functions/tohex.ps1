# ---- tohex - convert decimal values to hex

function tohex {
    [CmdletBinding()]
    param(
        [parameter(Position = 0, ValueFromPipeline)]
        [int] $Decimal
    )

    process {
        return ("{0:X2}" -f $Decimal)
    }
}
