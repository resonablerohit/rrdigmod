function Get-TenantDiagrams {
    [CmdletBinding()]
    param (
        [string[]] $ResourceGroups,
        [int] $LabelVerbosity = 1,
        [int] $CategoryDepth = 1,
        [string] $Direction = 'top-to-bottom',
        [string] $OutputFormat = 'svg',
        [string] $Theme = 'light',
        [string] $OutputFilePath,
        [string[]] $ExcludeTypes
    )

    if (!(Test-AzLogin)) {
        throw "Not logged into Azure. Please run Connect-AzAccount."
    }

    # Apply default values if not passed
    if (-not $ResourceGroups) {
        $ResourceGroups = (Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName)
    }

    $Parameters = @{
        Targets       = $ResourceGroups
        TargetType    = 'Azure Resource Group'
        LabelVerbosity = $LabelVerbosity
        CategoryDepth = $CategoryDepth
        Direction     = $Direction
        OutputFormat  = $OutputFormat
        Theme         = $Theme
        ExcludeTypes  = $ExcludeTypes
    }

    $dotLanguage = ConvertTo-DOTLanguage @Parameters

    if (-not $OutputFilePath) {
        $fileName = "AzureTenantDiagram_$(Get-Date -Format 'yyyyMMdd_HHmmss').$OutputFormat"
        $OutputFilePath = Join-Path -Path (Get-Location) -ChildPath $fileName
    }

    Write-CustomHost "Generating Diagram Output at: $OutputFilePath" -Indentation 1 -Color Green

    $GraphViz = Get-DOTExecutable
    if (-not $GraphViz) {
        throw "GraphViz is not installed. Please install it from https://graphviz.org/download/"
    }

    $tempDot = [System.IO.Path]::GetTempFileName() + ".dot"
    $dotLanguage | Out-File -FilePath $tempDot -Encoding ASCII -Force

    if (Test-Path $tempDot) {
        & $GraphViz.FullName -T$OutputFormat -O $tempDot
        $finalOutput = $tempDot -replace '\.dot$', ".$OutputFormat"
        Move-Item -Path $finalOutput -Destination $OutputFilePath -Force
        Remove-Item $tempDot -Force
        Write-CustomHost "✅ Diagram generated: $OutputFilePath" -Indentation 1 -Color Cyan
    } else {
        throw "DOT file was not generated. Aborting."
    }
}

