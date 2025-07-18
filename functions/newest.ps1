# ---- newest - returns the name of the most recently created item in PWD

function newest {
    $contents = (ls -attr !directory)
    if (-not ($contents.Count -ge 1)) {
        Write-Error "current directory doesn't contain any files"
        exit 1
    }
    return ($contents | sort CreationTime -desc)[0].Name
}
