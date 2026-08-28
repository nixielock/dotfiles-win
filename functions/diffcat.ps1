# ---- diffcat - compare two files

function diffcat {
    [CmdletBinding()]
    param(
        [parameter(Position = 0)]
        [string] $ReferencePath,

        [parameter(Position = 1)]
        [string] $DifferencePath,

        [parameter()]
        [ValidateSet('myers','minimal','patience','histogram')]
        [string] $Algorithm = 'histogram',

        [switch] $NoGit,

        [parameter()]
        [int] $SyncWindow = 10,

        [switch] $IncludeEqual
    )

    process {
        if ($NoGit) {
            $refContents = Get-Content $ReferencePath -ea Stop
            $diffContents = Get-Content $DifferencePath -ea Stop
            $result = Compare-Object $refContents $diffContents -SyncWindow $SyncWindow -IncludeEqual:$IncludeEqual

            if (-not $result) {
                if ((Get-FileHash $ReferencePath) -eq (Get-FileHash $DifferencePath)) {
                    ro "|@s|files are identical"
                } else {
                    ro "|@w|contents are identical, but files have different hashes"
                }
                return
            }
        
            $colors = @{
                '<=' = 'Red'
                '=>' = 'Green'
                '==' = 'Gray'
            }
            foreach ($line in $result) {
                Write-Host $line.InputObject -ForegroundColor $colors[$line.SideIndicator]
            }
        } else {
            git diff --diff-algorithm=$Algorithm --no-index -- $ReferencePath $DifferencePath
        }
    }
}
