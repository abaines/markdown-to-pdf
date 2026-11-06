# Read-only: for each direct npm dependency, shows the locked version and the newest
# stable release at least MinAgeDays old. Also lists current Node release lines.
# Changes nothing. Run from the repo root.
#
# Usage: .\llm-scratchpad\check-versions.ps1 [-MinAgeDays 2]
param([int]$MinAgeDays = 2)

$cutoff = (Get-Date).ToUniversalTime().AddDays(-$MinAgeDays)
$manifest = Get-Content package.json -Raw | ConvertFrom-Json
# Read as text: Windows PowerShell 5.1 can't parse the lockfile's empty-string key.
$lock = Get-Content package-lock.json -Raw

function Get-LockedVersion([string]$Name) {
    $pattern = '"node_modules/' + [regex]::Escape($Name) + '":\s*\{\s*"version":\s*"([^"]+)"'
    [regex]::Match($lock, $pattern).Groups[1].Value
}

function Get-NewestOldEnough([string]$Name) {
    $times = npm view $Name time --json 2>$null | ConvertFrom-Json
    $stable = foreach ($entry in $times.PSObject.Properties) {
        if ($entry.Name -match '^\d+\.\d+\.\d+$' -and [datetime]$entry.Value -le $cutoff) {
            [pscustomobject]@{ Version = [version]$entry.Name; Date = [datetime]$entry.Value }
        }
    }
    $stable | Sort-Object Version | Select-Object -Last 1
}

$rows = foreach ($dep in $manifest.dependencies.PSObject.Properties.Name) {
    $locked = Get-LockedVersion $dep
    $newest = Get-NewestOldEnough $dep
    $type = npm view "$dep@$($newest.Version)" type 2>$null
    $major = ([version]($locked -replace '-.*$', '')).Major -ne $newest.Version.Major
    [pscustomobject]@{
        Package  = $dep
        Locked   = $locked
        Newest   = $newest.Version
        Released = $newest.Date.ToString('yyyy-MM-dd')
        Major    = $major
        Module   = if ($type -eq 'module') { 'ESM' } else { 'CJS' }
    }
}
$rows | Format-Table -AutoSize

'--- Node release lines (active or maintenance)'
$schedule = Invoke-RestMethod 'https://raw.githubusercontent.com/nodejs/Release/main/schedule.json'
foreach ($line in $schedule.PSObject.Properties) {
    $released = [datetime]$line.Value.start -le (Get-Date)
    $supported = [datetime]$line.Value.end -gt (Get-Date)
    if ($released -and $supported) { "$($line.Name): start $($line.Value.start), lts $($line.Value.lts), end $($line.Value.end)" }
}
