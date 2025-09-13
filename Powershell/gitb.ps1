# Command to create new git branch respecting Elements branch naming pattern
# Usage:
# Type gitb, hit Tab, you should get suggestions based on your active work items
# example:
# gitb feature/1911296-PriceTemplateUi-CreatedetailsView
#
# Command to create new git branch from master respecting Elements branch naming pattern
# Usage:
# Type gitbm, hit Tab, you should get suggestions based on your active work items
# example:
# gitb feature/1911296-PriceTemplateUi-CreatedetailsView

$user = ""
$token = $Env:PAT
$assignedTo = $Env:gitb_assignedTo;

if ($null -eq $assignedTo) {
    Write-Host '$Env:gitb_assignedTo is required to work, example: Mateusz Kwiecinski <CCB@kmd.dk>'
}

if ($null -eq $token) {
    Write-Host '$Env:PAT is required to work, fetch PAT from Azure Devops'
}

function GetActiveWorkItems {
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))

    $uri = "https://dev.azure.com/kmddk/COMBAS/Team%201/_apis/wit/wiql?api-version=7.1"

    $body = "{
    'query':'SELECT    [System.Id],    [System.WorkItemType],    [System.Title],    [System.State],    [System.Tags] FROM workitems WHERE    [System.TeamProject] = \'COMBAS\'   AND [System.WorkItemType] in (\'User Story\', \'Bug\', \'Incident\' )    AND [System.State] in (\'Active\',\'Resolved\' )    AND [System.AssignedTo] = \'$assignedTo\''
}"
    try {

        $result = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) } -Body $body
    }
    catch {
        $exceptionMessage = $_.Exception.Message;
        return $exceptionMessage;
    }


    return $result.WorkItems | ForEach-Object {
        $getResult = Invoke-RestMethod -Uri $_.url -Method GET -ContentType "application/json" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }

        switch ($getResult.fields.'System.WorkItemType') {
            'User Story' { $prefix = 'feature/' }
            'Incident' { $prefix = 'incident/' }
            Default { $prefix = 'bug/' }
        }

        $toReplace = @("[BE]", "[FE]", "[BEFE]", "[E2E]", "[", "]", "/")
        $branchName = $getResult.fields.'System.Title'
        foreach ($pattern in $toReplace) {
            $branchName = $branchName.Replace($pattern, "")
        }
        $branchName = -join ($branchName.Trim() -split "\s" | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower() } )

        $concat = $prefix + ($_.id).ToString() + '-' + $branchName
        return $concat
    }
}

function gitb {
    param(
        [Parameter()]
        $ParameterName
    )
    $NewBranchName = $ParameterName
    $Counter = 1

    while ($true) {
        git checkout -b $NewBranchName

        if ($LASTEXITCODE -ne 0) {
            $NewBranchName = "$ParameterName$Counter"
            $Counter++
        } else {
            break
        }
    }
}

function gitbm {
    param(
        [Parameter()]
        $ParameterName
    )
    git checkout master
    git pull

    $NewBranchName = $ParameterName
    $Counter = 1

    while ($true) {
        git checkout -b $NewBranchName

        if ($LASTEXITCODE -ne 0) {
            $NewBranchName = "$ParameterName$Counter"
            $Counter++
        } else {
            break
        }
    }
}

$scriptBlock = {
    # The parameters passed into the script block by the
    #  Register-ArgumentCompleter command
    param(
        $commandName, $parameterName, $wordToComplete,
        $commandAst, $fakeBoundParameters
    )

    $values = GetActiveWorkItems

    foreach ($val in $values) {
        $val
    }
}

Register-ArgumentCompleter -CommandName gitb -ScriptBlock $scriptBlock
Register-ArgumentCompleter -CommandName gitbm -ScriptBlock $scriptBlock
