<#
.SYNOPSIS
    Exports Azure infrastructure topology and visualizes it using Graphviz.

.DESCRIPTION
    Generates a DOT language diagram of Azure resources from ARM templates and network associations,
    then exports to SVG (or PNG) format using Graphviz. Designed for large-scale infrastructures.

.PARAMETER ResourceGroup
    One or more Azure Resource Groups to visualize.

.PARAMETER OutputFormat
    Diagram output format: 'svg' (default) or 'png'.

.PARAMETER OutputFilePath
    Full path where the output diagram will be saved.

.PARAMETER Direction
    Graph layout direction: 'top-to-bottom' (default) or 'left-to-right'.

.PARAMETER CategoryDepth
    Controls resource sub-type resolution: 1 (default), 2, etc.

.PARAMETER LabelVerbosity
    Label detail level: 1 = name only, 2 = name + type.

.PARAMETER Theme
    Visual theme: 'light' (default), 'dark', or 'neon'.

.EXAMPLE
    Export-RrDigMod -ResourceGroup 'my-rg' -OutputFormat 'svg' -Direction 'left-to-right' -OutputFilePath './mydiagram.svg'
#>

function Export-RrDigMod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $ResourceGroup,

        [ValidateSet('svg', 'png')]
        [string] $OutputFormat = 'svg',

        [ValidateSet('top-to-bottom', 'left-to-right')]
        [string] $Direction = 'top-to-bottom',

        [string] $OutputFilePath = "$PWD\rrdigmod-output.svg",

        [ValidateSet(1,2,3)]
        [int] $CategoryDepth = 1,

        [ValidateSet(1,2)]
        [int] $LabelVerbosity = 1,

        [ValidateSet('light', 'dark', 'neon')]
        [string] $Theme = 'light'
    )

    begin {
        Write-CustomHost "🔧 Starting Export-RrDigMod..." -Color Cyan -AddTime

        if (!(Test-AzLogin)) {
            Write-CustomHost "❌ Not logged into Azure. Run Connect-AzAccount first." -Color Red
            return
        }

        # Validate Graphviz
        $dotExe = Get-DOTExecutable
        if (-not $dotExe) {
            Write-Error "'GraphViz' not installed. Download from https://graphviz.org/download/"
            return
        }

        # Set global theme colors
        Set-Theme -Theme $Theme
    }

    process {
        $Targets = $ResourceGroup
        $DOTString = ConvertTo-DOTLanguage -Targets $Targets `
                                           -TargetType 'Azure Resource Group' `
                                           -LabelVerbosity $LabelVerbosity `
                                           -CategoryDepth $CategoryDepth `
                                           -Direction $Direction `
                                           -Splines 'spline' `
                                           -ExcludeTypes @()

        $OutputFile = if ($OutputFilePath) { $OutputFilePath } else { "$PWD\rrdigmod-output.$OutputFormat" }

        Write-CustomHost "🖨️  Saving diagram to: $OutputFile" -Color Green -AddTime

        $tempDOT = New-TemporaryFile
        $DOTString | Out-File -FilePath $tempDOT -Encoding ascii

        & $dotExe.FullName -T$OutputFormat -o $OutputFile $tempDOT
        Remove-Item $tempDOT -Force

        if (Test-Path $OutputFile) {
            Write-CustomHost "✅ Export complete: $OutputFile" -Color Green -AddTime
        } else {
            Write-CustomHost "❌ Failed to generate the output diagram." -Color Red
        }
    }

    end {
        Write-CustomHost "🏁 Export-RrDigMod finished." -Color Cyan -AddTime
    }
}

