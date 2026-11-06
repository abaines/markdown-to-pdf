# One-off undo of normalize-working-tree.ps1: turns LF back into CRLF in the exact
# files that script changed. Those files were pure CRLF before, so this restores
# them byte for byte. Touches no git state. Run from the repo root.
#
# Usage: .\restore-crlf.ps1

$paths = @(
    '.gitignore', 'Dockerfile', 'LICENSE', 'README.md', 'action.yml',
    'docker-compose.yaml', 'package.json', 'src/github_interface.js',
    'src/markdown-to-pdf.d.ts', 'src/markdown-to-pdf.js', 'styles/highlight.css',
    'styles/markdown.css', 'template/template.html'
)

foreach ($path in $paths) {
    $full = Join-Path (Get-Location) $path
    $bytes = [System.IO.File]::ReadAllBytes($full)
    if ($bytes -contains 13) { throw "Already contains CR, stopping: $path" }

    $out = New-Object System.Collections.Generic.List[byte] ($bytes.Length + 1024)
    foreach ($byte in $bytes) {
        if ($byte -eq 10) { $out.Add(13) }
        $out.Add($byte)
    }

    [System.IO.File]::WriteAllBytes($full, $out.ToArray())
    "restored: $path"
}
