sal wr Write-Host
$highlight = 'magenta'
function wipe-line {
    param (
        [parameter(Position = 0)]
        [int] $Times = 1
    )

    for ($i = 0; $i -lt $Times; $i++) {
        wr "`e[1F`e[2K" -n
    }
}

function path-input {
    $outPath = $null
    while ($null -eq $outPath) {
      wr "    > " -f cyan -n
      $parsedInput = (gi (Read-Host) -ea SilentlyContinue)
      wipe-line
      if ($null -eq $parsedInput) {
        continue
      }
      if (-not ($parsedInput.PSIsContainer)) {
        wr "    path must be a directory!" -f yellow
        continue
      }
      $outPath = $parsedInput.FullName
      wr "    is " -n
      wr "$outPath" -f $highlight -n
      wr " correct? (Y/n) " -n
      wr "> " -f cyan -n
      if ((Read-Host) -match 'n') {
        $outPath = $null
        wipe-line
        continue
      }
      wipe-line
    }
    $outPath
}

$paths = @{}

wr "// running initialisation for local spec..."
wr "    welcome to the spellbook!" -f $highlight

# - main path
wr "    first up, the " -n
wr "main path" -f $highlight -n
wr " where you want all this set up"
$paths.MainPath = (path-input)
