# Read-only: downloads one artifact from each of two runs and compares them with
# compare-pdfs-in-container.sh. Changes nothing in the repo or on GitHub.
#
# Usage, from the repo root:
#   .\llm-scratchpad\compare-two-runs.ps1 -RunA <id> -ArtifactA <name> -RunB <id> -ArtifactB <name> -OutDir <folder>
param(
    [Parameter(Mandatory = $true)][string]$RunA,
    [Parameter(Mandatory = $true)][string]$ArtifactA,
    [Parameter(Mandatory = $true)][string]$RunB,
    [Parameter(Mandatory = $true)][string]$ArtifactB,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [string]$Image = 'markdown-to-pdf:dev',
    [string]$Repo = 'abaines/markdown-to-pdf'
)

function ConvertTo-WslPath([string]$Path) {
    wsl -e wslpath -u ($Path -replace '\\', '/')
}

$dirA = Join-Path $OutDir "a-$RunA"
$dirB = Join-Path $OutDir "b-$RunB"
New-Item -ItemType Directory -Force $dirA, $dirB | Out-Null
gh run download $RunA -R $Repo -n $ArtifactA -D $dirA
gh run download $RunB -R $Repo -n $ArtifactB -D $dirB

$a = ConvertTo-WslPath $dirA
$b = ConvertTo-WslPath $dirB
$script = ConvertTo-WslPath (Join-Path $PSScriptRoot 'compare-pdfs-in-container.sh')
wsl -e podman run --rm -v "${a}:/a:ro" -v "${b}:/b:ro" -v "${script}:/scratch/run.sh:ro" --entrypoint sh $Image /scratch/run.sh
