# dotfiles
# load the function globally when script is called

function dotfiles {
    param (
        [parameter(Position = 0, Mandatory)]
        [string] $FunctionsPath,

        [parameter(Position = 1, Mandatory)]
        [string] $RepositoryPath
    )

    # cd to repo
    $currentDir = $PWD.Path
    cd $RepositoryPath
    
    # set timestamp
    $dt = (Get-Date -f "yyyyMMddTHHmmss")
    
    # rename and gitignore existing functions directory
    $oldFunctionDir = "functions.old-$dt"
    rni .\functions $oldFunctionDir
    ac .\.gitignore -val $oldFunctionDir

    # rename and gitignore existing profile
    $oldProfile = "load.old-$dt.ps1"
    rni .\load.ps1 $oldProfile
    ac .\.gitignore -val $oldProfile

    # import current functions directory and profile
    cp -Recurse $FunctionsPath .\functions
    cp $profile .\load.ps1

    # add changes and display git status
    git add .
    git status
    
    # request commit message to confirm
    wr "enter a commit message to save changes:"
    wr "> " -f cyan -n
    $msg = (Read-Host)
    if (-not ($msg -match '\w')) {
        wr ""
        wr "no valid commit message, changes not committed" -f yellow
        return ""
    }
    
    # commit changes
    git commit -m "$msg"
    wr "push to remote? (y/N) " -n
    wr "> " -f cyan -n
    if ((Read-Host) -match 'y') {
        git push
    }
}
