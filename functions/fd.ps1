# ---- fd - display the name, type, count and value of each property of the input object
# ('fd' as in 'Format-Data' but that name feels too broad for this weird lil display utility)

function fd {
    [CmdletBinding()]
    param(
        # input object to display properties for
        [parameter(Position = 0, ValueFromPipeline)]
        [object] $InputObject,

        # show the entire printed value of each property
        [Alias('s')]
        [switch] $ShowFullValues
    )

    process {
        $properties = $InputObject.PSObject.Properties.Name
        $limWidth = $Host.UI.RawUI.WindowSize.Width - 4
        if ($limWidth -lt 1) {
            throw "your $($Host.UI.RawUI.WindowSize.Height)x$columns terminal size is bogus. expect trouble"
        }

        foreach ($p in $properties) {
            $val = $InputObject.$p
            if ($null -eq $val) {
                ro "|@d|$p |@b|-- |@d|null"
                continue
            }

            $typeCheck = (typecheck $val)
            $typeDesc = "[$($typeCheck.Description)]" -replace ' \((empty|\d+ items)\)\]$', '] |@white|($1)'
            ro "|@green|$p |@b|-- |@darkgreen|$typeDesc"

            if ($typeDesc -match '\(empty\)$') { continue }

            if ($typeCheck.AutoEnumerate) {
                if ($ShowFullValues) {
                    $outString = "{$($val -join ', ')}"
                } else {
                    $listBuffer = @()
                    foreach ($item in $val) {
                        if ((($listBuffer -join ', ').Length + "$item".Length + 5) -gt $limWidth) {
                            $listBuffer += "..."
                            break
                        }
                        $listBuffer += "$item"
                    }
                    $outString = "{$($listBuffer -join ', ')}"
                }
            } elseif ($typeCheck.Dictionary) {
                if ($ShowFullValues) {
                    $innerString = ($val.Keys |% { "[$_, $($val[$_])]" }) -join ', '
                    $outString = "{$innerString}"
                } else {
                    $listBuffer = @()
                    foreach ($key in $val.Keys) {
                        $item = "[$key, $($val[$key])]"
                        if ((($listBuffer -join ', ').Length + $item.Length + 5) -gt $limWidth) {
                            $listBuffer += "..."
                            break
                        }
                        $listBuffer += $item
                    }
                    $outString = "{$($listBuffer -join ', ')}"
                }
            } else {
                $outString = "$val"
            }

            if ($ShowFullValues) {
                $buffer = @()
                while ($outString.Length -gt $limWidth) {
                    $buffer += "".PadLeft(4), $outString.Substring(0, $limWidth) -join ''
                    $outString = $outString.Substring($limWidth)
                }
                $buffer += "".PadLeft(4), $outString -join ''
                ro ($buffer -join "`n")
            } else {
                ro "    $outString"
            }
        }
    }
}

