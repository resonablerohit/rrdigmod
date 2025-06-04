function Export-RrDigMod {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'AzLogin', Mandatory = $true, Position = 0)]
        [string[]] $ResourceGroup,

        [Parameter(ParameterSetName = 'AzLogin')]
        [switch] $Show,

        [Parameter(ParameterSetName = 'AzLogin')]
        [ValidateSet(1, 2, 3)]
        [int] $LabelVerbosity = 2,

        [Parameter(ParameterSetName = 'AzLogin')]
        [ValidateSet(1, 2, 3)]
        [int] $CategoryDepth = 2,

        [Parameter(ParameterSetName = 'AzLogin')]
        [ValidateSet('png', 'svg')]
        [string] $OutputFormat = 'svg',

        [Parameter(ParameterSetName = 'AzLogin')]
        [ValidateSet('light', 'dark', 'neon')]
        [string] $Theme = 'light',

        [Parameter(ParameterSetName = 'AzLogin')]
        [ValidateSet('left-to-right', 'top-to-bottom')]
        [string] $Direction = 'top-to-bottom',

        [Parameter(ParameterSetName = 'AzLogin')]
        [string] $OutputFilePath = (Join-Path ([System.IO.Path]::GetTempPath()) "rrdigmod_output.svg"),

        [Parameter(ParameterSetName = 'AzLogin')]
        [ValidateSet('polyline', 'curved', 'ortho', 'line', 'spline')]
        [string] $Splines = 'spline',

        [Parameter(ParameterSetName = 'AzLogin')]
        [string[]] $ExcludeTypes
    )

    try {
        $ErrorActionPreference = 'Stop'
        $StartTime = [datetime]::Now

        Write-Host "`n🎯 Starting rrdigmod SVG export..."
        $GraphViz = Get-DOTExecutable
        if (-not $GraphViz) {
            Write-Error "❌ Graphviz is not installed. Please install from https://graphviz.org/download/." -ErrorAction Stop
        }

        # Thematic Colors
        . "$PSScriptRoot/../private/ThemeHandler.ps1" -Theme $Theme

        $TargetType = 'Azure Resource Group'
        $Targets = $ResourceGroup

        Write-Host "⚙️  Configuration:"
        Write-Host "  RGs: $($ResourceGroup -join ', ')"
        Write-Host "  Format: $OutputFormat"
        Write-Host "  Theme: $Theme"
        Write-Host "  Label Verbosity: $LabelVerbosity"
        Write-Host "  Category Depth: $CategoryDepth"
        Write-Host "  Output Path: $OutputFilePath"

        # Generate .dot
        $GraphDot = ConvertTo-DOTLanguage `
            -TargetType $TargetType `
            -Targets $Targets `
            -CategoryDepth $CategoryDepth `
            -LabelVerbosity $LabelVerbosity `
            -Splines $Splines `
            -ExcludeTypes $ExcludeTypes `
            -IconDirectory (Join-Path $PSScriptRoot '../../icons') `
            -OutputFormat $OutputFormat `
            -Theme $Theme `
            -Direction $Direction

        if ($GraphDot) {
            @"
strict $GraphDot
"@ | Export-PSGraph `
    -GraphVizPath $GraphViz.FullName `
    -ShowGraph:$Show `
    -OutputFormat $OutputFormat `
    -DestinationPath $OutputFilePath |
    Out-Null

            Write-Host "`n✅ Export completed: $OutputFilePath"
        } else {
            Write-Warning "No DOT graph content generated."
        }
    } catch {
        Write-Error "❌ Error: $_"
    }
}

Export-ModuleMember -Function Export-RrDigMod

