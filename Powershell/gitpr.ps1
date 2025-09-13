# Command to create pull request based on current branch name
# Your pull request info will be taken from work item from current branch name
# Title -> WorkItem.Title
# Description -> WorkItem.Description + AcceptanceCriteria
# Usage:
# Type gitpr, enter

$user = ""
$token = $Env:PAT

if ($null -eq $token) {
    Write-Host '$Env:PAT is required to work, fetch PAT from Azure Devops'
}

function CreatePr {
    if (-not (Test-Path -Path ".git" -PathType Container)) {
        Write-Error "Not a git directory, exit"
        return
    }

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))

    $currentBranch = git rev-parse --abbrev-ref HEAD
    if ($currentBranch -notmatch "\d+") {
        Write-Error "Not supported branch name"
        return
    }
    $workItemId = $matches[0]
    $getWorkItemId = "https://dev.azure.com/kmddk/COMBAS/_apis/wit/workitems/" + $workItemId + "?api-version=7.1"
    $workItemInfo = Invoke-RestMethod -Uri $getWorkItemId -Method Get -ContentType "application/json" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }

    $repoName = git config --get remote.origin.url
    $repoName = $repoName -replace '^.*\/', '' # Assuming HTTPS clone URL
    $repoName = $repoName -replace '\.git$', '' # Remove .git extension

    $currentBranch = git rev-parse --abbrev-ref HEAD

    $uri = "https://dev.azure.com/kmddk/COMBAS/_apis/git/repositories/$repoName/pullrequests?api-version=7.0"

    switch ($workItemInfo.fields.'System.WorkItemType') {
        'User Story' {
            $pullRequestDescription = "Context:`r`n" + $workItemInfo.fields.'System.Description' + "`r`n`r`nAcceptance criteria:`r`n" + $workItemInfo.fields.'Microsoft.VSTS.Common.AcceptanceCriteria'
            $titlePrefix = "feat: "
        }
        'Incident' {
            $pullRequestDescription = "Context:`r`n" + $workItemInfo.fields.'System.Description' + "`r`n`r`nAcceptance criteria:`r`n" + $workItemInfo.fields.'Microsoft.VSTS.Common.AcceptanceCriteria'
            $titlePrefix = "fix: "
        }
        Default {
            $pullRequestDescription = $workItemInfo.fields.'Microsoft.VSTS.TCM.ReproSteps'
            $titlePrefix = "fix: "
        }
    }

    $body = @{
        sourceRefName = "refs/heads/$currentBranch"
        targetRefName = "refs/heads/master"
        title         = $titlePrefix + $workItemInfo.fields.'System.Title'
        description   = $pullRequestDescription
        reviewers     = @()
    } | ConvertTo-Json


    $result = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) } -Body $body

    $pullRequestUrl = "https://dev.azure.com/kmddk/COMBAS/_git/$repoName/pullrequest/$($result.pullRequestId)"
    $pullRequestUrl
}

Set-Alias -Name gitpr -Value CreatePr
