# Rewrites tracked files that are LF in git but CRLF on disk, so the working tree
# matches the index. Touches no git state. Works on raw bytes, so encoding is kept.
# Run from the repo root after adding `* text=auto eol=lf` to .gitattributes.
#
# Usage: .\normalize-working-tree.ps1

$crlf = git ls-files --eol | Where-Object { $_ -match '^i/lf\s+w/crlf' }

foreach ($line in $crlf) {
    $path = ($line -split "`t", 2)[1]
    $full = Join-Path (Get-Location) $path
    $bytes = [System.IO.File]::ReadAllBytes($full)
    $out = New-Object System.Collections.Generic.List[byte] $bytes.Length

    for ($i = 0; $i -lt $bytes.Length; $i++) {
        $isCrBeforeLf = $bytes[$i] -eq 13 -and $i + 1 -lt $bytes.Length -and $bytes[$i + 1] -eq 10
        if (-not $isCrBeforeLf) { $out.Add($bytes[$i]) }
    }

    [System.IO.File]::WriteAllBytes($full, $out.ToArray())
    "normalized: $path"
}

"files normalized: $(@($crlf).Count)"
