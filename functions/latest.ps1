# ---- latest - returns the name of the most recently-updated item in PWD

function latest {
    param (
        [parameter(Position = 0)]
        [int] $Count = 1
    )

    $contents = (gci -attr !directory)
    if (-not ($contents.Count -ge 1)) {
        Write-Error "current directory doesn't contain any files"
        exit 1
    }

    $endIndex = [math]::Max(($Count - 1), 0)
    $endIndex = [math]::Min($endIndex, ($contents.Count - 1))
    return ($contents | sort LastWriteTime -desc)[0..$endIndex].Name
}
