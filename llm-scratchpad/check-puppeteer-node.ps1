# Read-only: for the newest release of each Puppeteer major, shows the Node versions
# it supports and its release date, to find a version that bridges two Node releases.
#
# Usage: .\llm-scratchpad\check-puppeteer-node.ps1 [-Majors 21,22,23,24,25]
param([int[]]$Majors = @(19, 20, 21, 22, 23, 24, 25))

$times = npm view puppeteer time --json 2>$null | ConvertFrom-Json

foreach ($major in $Majors) {
    $newest = $times.PSObject.Properties |
        Where-Object { $_.Name -match "^$major\.\d+\.\d+$" } |
        Sort-Object { [version]$_.Name } |
        Select-Object -Last 1

    if ($newest) {
        $node = npm view "puppeteer@$($newest.Name)" engines.node 2>$null
        "{0,-10} released {1}  node {2}" -f $newest.Name, ([datetime]$newest.Value).ToString('yyyy-MM-dd'), $node
    }
}
