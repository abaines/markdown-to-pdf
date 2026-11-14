# Read-only: summarizes npm audit findings for the current lockfile, showing each
# vulnerable package, its severity, and which direct dependency brings it in.
#
# Usage, from the repo root: .\llm-scratchpad\audit-summary.ps1 [-Image <image>]
param([string]$Image = 'localhost/markdown-to-pdf:refactor')

$raw = wsl -e sh scripts/npm-in-image.sh $Image audit --json 2>$null
$report = ($raw -join "`n") | ConvertFrom-Json
$vulns = $report.vulnerabilities.PSObject.Properties.Value

$direct = @($vulns | Where-Object { $_.isDirect } | ForEach-Object { $_.name })

function Get-Roots($Vuln, $Seen = @()) {
    if ($Vuln.isDirect) { return $Vuln.name }
    foreach ($parent in $Vuln.effects) {
        if ($Seen -notcontains $parent) {
            $next = $report.vulnerabilities.$parent
            if ($next) { Get-Roots $next ($Seen + $Vuln.name) }
        }
    }
}

$rows = foreach ($vuln in $vulns) {
    $titles = @($vuln.via | Where-Object { $_.title } | ForEach-Object { $_.title })
    [pscustomobject]@{
        Package  = $vuln.name
        Severity = $vuln.severity
        Direct   = $vuln.isDirect
        From     = (@(Get-Roots $vuln) | Sort-Object -Unique) -join ', '
        Advisories = $titles.Count
    }
}

$order = @{ critical = 0; high = 1; moderate = 2; low = 3 }
$rows | Sort-Object { $order[$_.Severity] }, Package | Format-Table -AutoSize

'--- totals'
$report.metadata.vulnerabilities | ConvertTo-Json -Compress
"direct packages with findings: $($direct -join ', ')"
