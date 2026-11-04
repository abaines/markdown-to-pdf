# Read-only safety check: lists the workflow files on every branch of a GitHub
# repo, then flags any file that differs from the default branch, plus any
# privileged or automatic triggers. Only makes GET requests; changes nothing.
#
# Usage: .\check-workflows-across-refs.ps1 [-Repo owner/name] [-Base main]
param(
    [string]$Repo = 'abaines/markdown-to-pdf',
    [string]$Base = 'main'
)

$risky = 'pull_request_target|workflow_run|schedule|issue_comment|repository_dispatch|issues:|release:|secrets\.'

$branches = gh api "repos/$Repo/branches?per_page=100" --paginate --jq '.[].name'
"Branches found: $(@($branches).Count)"

function Get-Workflows([string]$ref) {
    # @tsv avoids embedded double quotes, which Windows PowerShell 5.1 strips
    # from native command arguments.
    $rows = gh api "repos/$Repo/contents/.github/workflows?ref=$ref" --jq '.[] | [.path, .sha] | @tsv' 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    $map = @{}
    foreach ($row in $rows) {
        $parts = $row -split "`t"
        $map[$parts[0]] = $parts[1]
    }
    return $map
}

$baseMap = Get-Workflows $Base
if ($null -eq $baseMap) { throw "Could not read workflows on base ref '$Base'; aborting so the result is not misread as clean." }

foreach ($branch in $branches) {
    "=== $branch"
    $map = Get-Workflows $branch
    if ($null -eq $map) { '  (no .github/workflows directory, or read failed)'; continue }
    foreach ($path in ($map.Keys | Sort-Object)) {
        $state = if ($baseMap[$path] -eq $map[$path]) { 'same as base' } else { 'DIFFERS' }
        "  $path  $($map[$path].Substring(0,8))  $state"
        $raw = gh api "repos/$Repo/git/blobs/$($map[$path])" -H 'Accept: application/vnd.github.raw'
        $hits = $raw | Select-String -Pattern $risky
        foreach ($hit in $hits) { "      flag: $($hit.Line.Trim())" }
    }
}
