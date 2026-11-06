# Read-only diagnosis of a failed GHCR push from a workflow run.
# Shows the token permissions the job received and the push log, then asks GHCR
# anonymously whether the package already exists. Sends no credentials to GHCR.
#
# Usage: .\diagnose-ghcr-push.ps1 -Run <run_id> [-Repo owner/name] [-Image owner/name]
param(
    [Parameter(Mandatory = $true)][string]$Run,
    [string]$Repo = 'abaines/markdown-to-pdf',
    [string]$Image = 'abaines/markdown-to-pdf'
)

$log = gh run view $Run -R $Repo --log

'--- GITHUB_TOKEN permissions the job received'
$log | Select-String -Pattern 'Set up job.*(Contents|Metadata|Packages):' |
    ForEach-Object { ($_.Line -split '\s+', 4)[-1] }

'--- login step'
$log | Select-String -Pattern 'Log in to GHCR.*(Login|WARNING|Succeeded)' |
    ForEach-Object { $_.Line.Substring(0, [Math]::Min(150, $_.Line.Length)) }

'--- push step'
$log | Select-String -Pattern '^publish\s+Push image' | Select-Object -Last 14 |
    ForEach-Object { $_.Line.Substring(0, [Math]::Min(170, $_.Line.Length)) }

'--- anonymous GHCR check'
try {
    $token = (Invoke-RestMethod "https://ghcr.io/token?scope=repository:${Image}:pull").token
    "anonymous pull token issued: $([bool]$token)"
    $tags = Invoke-RestMethod "https://ghcr.io/v2/$Image/tags/list" -Headers @{ Authorization = "Bearer $token" }
    # A name that doesn't exist returns 403 here, so reaching this line means it exists.
    "anonymous read allowed; tags: $($tags.tags -join ', ')"
} catch {
    "request failed: $($_.Exception.Response.StatusCode.value__) $($_.Exception.Message)"
}
