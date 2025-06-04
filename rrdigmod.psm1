# Entry point: dynamically dot-source all .ps1 files under ./src
$Path = Join-Path $PSScriptRoot 'src'

Get-ChildItem $Path -Filter *.ps1 -Recurse | ForEach-Object {
    Write-Host "🔄 Loading: $($_.FullName)"
    . $_.FullName
}

Write-Host "✅ Module loaded: rrdigmod"
