# ---- wqe - display installed packages

function wqe {
    [CmdletBinding()]
    param (
        [Alias('i')]
        [ValidateSet("Regular","MSIX","ARP")]
        [string[]] $Category = "Regular"
    )

    begin {
        function version {
            [CmdletBinding()]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                $Package
            )

            $current = $pkg.InstalledVersion
            $latest = $pkg.AvailableVersions[0]
            $vInfo = [PSCustomObject]@{
                Installed = $current
                Latest = $latest
                Behind = 0
            }

            if ($latest -eq $current) {
                return $vInfo # up to date
            }

            if ($pkg.AvailableVersions -contains $current) {
                $vInfo.Behind = $pkg.AvailableVersions.IndexOf($current)
                return $vInfo # outdated
            } elseif ($current -match '\.0$') {
                $sansZero = $current -replace '\.0$', ''
                if ($pkg.AvailableVersions -contains $sansZero) {
                    $vInfo.Behind = $pkg.AvailableVersions.IndexOf($sansZero)
                    return $vInfo # outdated
                }
            }

            $currentSplit = ($current -split '\.')
            $latestSplit = ($latest -split '\.')
            $maxCount = [math]::Max($currentSplit.Count, $latestSplit.Count)

            for ($i = 0; $i -lt $maxCount; $i++) {
                $cPart = ($currentSplit[$i] -as [int]) ?? $currentSplit[$i]
                $lPart = ($latestSplit[$i] -as [int]) ?? $latestSplit[$i]
                if ($cPart -gt $lPart) {
                    $vInfo.Behind = -1
                    return $vInfo # newer
                } elseif ($cPart -lt $lPart) {
                    $vInfo.Behind = $null
                    return $vInfo # unknown
                }
            }
            return $vInfo # same version, different string representations
        }

        $PackageCategories = @{
            Regular = [PSCustomObject]@{
                Text = 'regular'
                Filter = { $_.Id -notmatch '^(?:MSIX|ARP)\\' }
            }
            MSIX = [PSCustomObject]@{
                Text = 'Microsoft'
                Filter = { $_.Id -match '^MSIX\\' }
            }
            ARP = [PSCustomObject]@{
                Text = 'ARP'
                Filter = { $_.Id -match '^ARP\\' }
            }
        }
    }

    process {
        $packages = Get-WingetPackage

        foreach ($selected in $Category) {
            $text = $PackageCategories[$selected].Text

            $selectPackages = $packages |? ($PackageCategories[$selected].Filter)
            $displayPackages = [System.Collections.Generic.List[PSCustomObject]]::new()
            foreach ($pkg in $selectPackages) {
                if ($selected -eq "MSIX") {
                    $pkgTitle = $pkg.Id -replace 'MSIX\\([^_]+)_.*', '$1'
                } elseif ($selected -eq "ARP") {
                    $pkgTitle = $pkg.Name
                } else {
                    $pkgTitle = $pkg.Id
                }
                $pkgInfo = version $pkg

                $displayPackages.Add(([PSCustomObject]@{
                    Title   = $pkgTitle
                    Current = $pkgInfo.Installed
                    Latest  = $pkgInfo.Latest
                    Behind  = $pkgInfo.Behind
                }))
            }

            ro "displaying |@b|$($selectPackages.Count) |@|$text packages:"
            $padName = ($displayPackages.Title | Measure-Object Length -Maximum).Maximum
            $padCurrent = ($displayPackages.Current | Measure-Object Length -Maximum).Maximum
            foreach ($pkg in $displayPackages) {
                $title = $pkg.Title
                $current = $pkg.Current
                $latest = $pkg.Latest
                $behind = $pkg.Behind
                $padVer = "".PadRight(($padName - $title.Length))
                $padOp = "".PadRight(($padCurrent - $current.Length))

                if (-not $latest) {
                    ro " $title $padVer|@dgreen|$current"
                    continue
                }

                switch ($behind) {
                    0 {
                        if ($current -eq $latest) {
                            ro "  $title $padVer|@dgreen|$current"
                        } else {
                            ro "  $title $padVer|@dgreen|$current $padOp|@d|== $latest"
                        }
                            
                    }
                    -1 {
                        ro "  $title $padVer|@dgreen|$current $padOp|@d|<- |@dcyan|$latest |@d|(installed is newer)"
                    }
                    $null {
                        ro "- $title $padVer|@w|$current $padOp|@|-> |@p|$latest |@d|(?)"
                    }
                    1 {
                        ro "- $title $padVer|@w|$current $padOp|@|-> |@p|$latest"
                    }
                    default {
                        ro "- $title $padVer|@e|$current $padOp|@|-> |@p|$latest |@e|($behind versions behind)"
                    }
                }
            }
            [Console]::WriteLine()
        }
    }
}
