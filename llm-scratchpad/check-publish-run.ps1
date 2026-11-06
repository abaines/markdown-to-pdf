# Read-only: reports a workflow run's result, steps in order, artifacts and any
# published digest, and lists the latest runs so a missing one is visible.
#
# Usage: .\llm-scratchpad\check-publish-run.ps1 -Run <run_id> [-Repo owner/name]
param(
    [Parameter(Mandatory = $true)][string]$Run,
    [string]$Repo = 'abaines/markdown-to-pdf'
)

gh run view $Run -R $Repo --json workflowName,headSha,conclusion,createdAt,updatedAt --jq '[.workflowName,.headSha,.conclusion,.createdAt,.updatedAt] | @tsv'

'--- steps'
gh run view $Run -R $Repo --json jobs --jq '.jobs[] | .name as $job | .steps[] | [$job,.name,.conclusion] | @tsv'

'--- artifacts'
gh api "repos/$Repo/actions/runs/$Run/artifacts" --jq '.artifacts[] | [.name,.size_in_bytes] | @tsv'

'--- render check and digest lines'
gh run view $Run -R $Repo --log |
    Select-String -Pattern 'render-check: |: digest: sha256|^.*Print digest.*ghcr\.io/.*@sha256:[0-9a-f]{64}$' |
    ForEach-Object { $_.Line.Substring(0, [Math]::Min(200, $_.Line.Length)) }

'--- latest runs'
gh run list -R $Repo --limit 4 --json databaseId,workflowName,conclusion,headSha,createdAt --jq '.[] | [.databaseId,.workflowName,.conclusion,.headSha[0:7],.createdAt] | @tsv'
