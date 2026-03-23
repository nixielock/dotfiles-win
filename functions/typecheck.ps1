function typecheck {
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param (
    [parameter(Position = 0, ValueFromPipeline)]
    [object] $InputObject,

    [parameter()]
    [Alias('p')]
    [switch] $ShowPropertyCount
  )

  process {
    if ($null -eq $InputObject) {
      return [PSCustomObject]@{
        Name = "null"
        AutoEnumerate = $false
        Collection = $false
        Dictionary = $false
        List = $false
        Description = "null"
      }
    }

    $typeDetails = $InputObject.GetType()

    $outData = [PSCustomObject]@{
      Name = $typeDetails.ToString().Replace("$($typeDetails.Namespace).", "")
      AutoEnumerate = (
        (
          $InputObject -is [System.Collections.IEnumerable] -and
          $InputObject -isnot [System.Collections.IDictionary] -and
          $InputObject -isnot [string] -and
          $InputObject -isnot [System.Xml.XmlNode]
        ) -or (
          $InputObject -is [System.Data.DataTable] -or
          $InputObject -is [System.Collections.IEnumerator]
        )
      )
      Collection = $InputObject -is [System.Collections.ICollection]
      Dictionary = $InputObject -is [System.Collections.IDictionary]
      List = $InputObject -is [System.Collections.IList]
      PropertyCount = $InputObject.PSObject.Properties.Name.Count
      Description = ""
    }

    $outData.Name = $outData.Name -replace 'System\.(\w+)(?!=\.)', { $_.Groups[1].Value.ToLower() }
    $outData.Name = $outData.Name -replace 'boolean', 'bool'
    $outData.Name = $outData.Name -replace '`\d', ''
    if ($typeDetails.ToString() -match '^System\.\w+(?:\[\])?$') {
      $outData.Name = $outData.Name -replace '^\w', { $_.Value.ToLower() }
    }

    $outData.Description = $outData.Name
    if ($outData.Collection) {
      if ($InputObject.Count -ge 1) {
        $outData.Description += " ($($InputObject.Count) items)"
      } else {
        $outData.Description += " (empty)"
      }
    } elseif ($InputObject -is [string] -and $InputObject -notmatch '\S') {
      $outData.Description += " (empty)"
    } elseif ($ShowPropertyCount) {
      if (-not ($InputObject -is [string] -or $typeDetails.IsValueType)) {
        $outData.Description += " (p:$($outData.PropertyCount))"
      }
    }

    return $outData
  }
}
