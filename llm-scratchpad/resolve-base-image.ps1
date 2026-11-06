# Read-only: looks up tags of the official node image on Docker Hub and reports each
# tag's multi-arch index digest and when it was last pushed.
#
# Usage: .\llm-scratchpad\resolve-base-image.ps1 -Tags 26,26-bookworm,26-trixie
#        .\llm-scratchpad\resolve-base-image.ps1 -Search 26. -Suffix -bookworm -MinAgeDays 7
param(
    [string[]]$Tags,
    [string]$Search,
    [string]$Suffix = '',
    [int]$MinAgeDays = 0
)

function Format-Tag($Info) {
    $age = [math]::Round(((Get-Date).ToUniversalTime() - [datetime]$Info.tag_last_pushed).TotalDays, 1)
    if ($age -ge $MinAgeDays) {
        "{0,-22} {1}  pushed {2} ({3} days ago)" -f $Info.name, $Info.digest, $Info.tag_last_pushed, $age
    }
}

foreach ($tag in $Tags) {
    try {
        Format-Tag (Invoke-RestMethod "https://hub.docker.com/v2/repositories/library/node/tags/$tag")
    } catch {
        "{0,-22} not found" -f $tag
    }
}

if ($Search) {
    $url = "https://hub.docker.com/v2/repositories/library/node/tags?page_size=100&name=$Search"
    $results = (Invoke-RestMethod $url).results
    $matching = $results | Where-Object { $_.name -match ('^' + [regex]::Escape($Search) + '\d+\.\d+' + [regex]::Escape($Suffix) + '$') }
    $matching | Sort-Object { [version]($_.name -replace '-.*$', '') } -Descending | ForEach-Object { Format-Tag $_ }
}
