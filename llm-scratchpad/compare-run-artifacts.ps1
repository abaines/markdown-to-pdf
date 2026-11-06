# Read-only check of a Smoke test run: reports the jobs, render-check output and
# artifacts, downloads both artifacts, then compares them in a container using
# compare-pdfs-in-container.sh. Changes nothing in the repo or on GitHub.
#
# Usage, from the repo root:
#   .\llm-scratchpad\compare-run-artifacts.ps1 -Run <run_id> -OutDir <folder> [-Image <image>]
param(
    [Parameter(Mandatory = $true)][string]$Run,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [string]$Image = 'markdown-to-pdf:dev',
    [string]$Repo = 'abaines/markdown-to-pdf'
)

function ConvertTo-WslPath([string]$Path) {
    wsl -e wslpath -u ($Path -replace '\\', '/')
}

gh run view $Run -R $Repo --json workflowName,headSha,conclusion,createdAt,updatedAt --jq '[.workflowName,.headSha,.conclusion,.createdAt,.updatedAt] | @tsv'

'--- jobs'
gh run view $Run -R $Repo --json jobs --jq '.jobs[] | [.name,.conclusion,.startedAt,.completedAt] | @tsv'

'--- render-check output'
gh run view $Run -R $Repo --log |
    Select-String -Pattern 'render-check: ' |
    ForEach-Object { $_.Line.Substring(0, [Math]::Min(150, $_.Line.Length)) }

$names = 'render-from-commit', 'render-from-pinned-image'
foreach ($name in $names) {
    "--- $name"
    $dir = Join-Path $OutDir $name
    New-Item -ItemType Directory -Force $dir | Out-Null
    gh run download $Run -R $Repo -n $name -D $dir
    Get-ChildItem $dir | Select-Object Name, Length | Format-Table -HideTableHeaders
}

'--- compare'
$a = ConvertTo-WslPath (Join-Path $OutDir $names[0])
$b = ConvertTo-WslPath (Join-Path $OutDir $names[1])
$script = ConvertTo-WslPath (Join-Path $PSScriptRoot 'compare-pdfs-in-container.sh')
wsl -e podman run --rm -v "${a}:/a:ro" -v "${b}:/b:ro" -v "${script}:/scratch/run.sh:ro" --entrypoint sh $Image /scratch/run.sh
