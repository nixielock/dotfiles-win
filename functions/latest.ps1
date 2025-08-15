# ---- latest - returns the name of the most recently-updated item in PWD

function latest {
    $contents = (ls -attr !directory)
    if (-not ($contents.Count -ge 1)) {
        Write-Error "current directory doesn't contain any files"
        exit 1
    }
    return ($contents | sort LastWriteTime -desc)[0].Name
}
