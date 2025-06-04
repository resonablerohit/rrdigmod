# Load private helper scripts
$PrivateScripts = Get-ChildItem -Path (Join-Path $PSScriptRoot 'src/private') -Filter *.ps1
foreach ($script in $PrivateScripts) {
    Write-Verbose "Loading: $($script.FullName)"
    . $script.FullName
}

# Load public functions
$PublicScripts = Get-ChildItem -Path (Join-Path $PSScriptRoot 'src/public') -Filter *.ps1
foreach ($script in $PublicScripts) {
    Write-Verbose "Loading: $($script.FullName)"
    . $script.FullName
}

# Export public functions explicitly (optional if you're using FunctionsToExport in .psd1)
Export-ModuleMember -Function 'Export-RrDigMod'

