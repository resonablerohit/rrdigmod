# Load all ps1 files
$Path = Join-Path $PSScriptRoot 'src'
Get-ChildItem $Path -Filter *.ps1 -Recurse | ForEach-Object {
    . $_.FullName
}
Write-Host "✅ Module loaded: rrdigmod"
