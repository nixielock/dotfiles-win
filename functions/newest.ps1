# ---- newest - returns the name of the most recently created item in PWD

function newest {
    param (
        [parameter(Position = 0)]
        [int] $Count = 1
    )

    $contents = (ls -attr !directory)
    if (-not ($contents.Count -ge 1)) {
        Write-Error "current directory doesn't contain any files"
        exit 1
    }

    $endIndex = [math]::Max(($Count - 1), 0)
    $endIndex = [math]::Min($endIndex, ($contents.Count - 1))
    return ($contents | sort CreationTime -desc)[0..$endIndex].Name
}
