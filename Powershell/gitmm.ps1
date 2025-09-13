function gitMergeMaster {
    git checkout master
    git pull
    git checkout -
    git merge master
}

Set-Alias -Name gitmm -Value gitMergeMaster
