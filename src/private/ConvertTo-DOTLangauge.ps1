<#
.SYNOPSIS
    Converts Azure resources into DOT language for visualization.

.DESCRIPTION
    This script processes Azure resources and generates a DOT language representation,
    integrating icons and handling various resource types.

.PARAMETER Resources
    The list of Azure resources to process.

.PARAMETER IconMappings
    A hashtable mapping resource types to icon file paths.

.EXAMPLE
    ConvertTo-DOTLanguage -Resources $resources -IconMappings $iconMappings
#>

param (
    [Parameter(Mandatory = $true)]
    [array]$Resources,

    [Parameter(Mandatory = $true)]
    [hashtable]$IconMappings
)

function Get-IconPath {
    param (
        [string]$ResourceType
    )

    $key = $ResourceType.ToLower()
    if ($IconMappings.ContainsKey($key)) {
        return $IconMappings[$key]
    } else {
        Write-Warning "Icon not found for resource type: $ResourceType"
        return $null
    }
}

function Convert-ResourceToDOTNode {
    param (
        [object]$Resource
    )

    $resourceId = $Resource.id -replace '[^a-zA-Z0-9]', '_'
    $label = $Resource.name
    $iconPath = Get-IconPath -ResourceType $Resource.type

    if ($iconPath) {
        return "$resourceId [label=<$label>, image=""$iconPath"", shape=none];"
    } else {
        return "$resourceId [label=""$label"", shape=box];"
    }
}

function Convert-ResourcesToDOT {
    param (
        [array]$Resources
    )

    $dotOutput = @()
    $dotOutput += "digraph AzureResources {"
    $dotOutput += "    rankdir=LR;"
    $dotOutput += "    node [fontsize=10, fontname=""Segoe UI""];"

    foreach ($resource in $Resources) {
        try {
            $dotNode = Convert-ResourceToDOTNode -Resource $resource
            $dotOutput += "    $dotNode"
        } catch {
            Write-Error "Error processing resource: $($resource.name). $_"
        }
    }

    $dotOutput += "}"
    return $dotOutput -join "`n"
}

# Main execution
$dotGraph = Convert-ResourcesToDOT -Resources $Resources
$dotGraph | Out-File -FilePath "AzureResources.dot" -Encoding UTF8
Write-Output "DOT file generated: AzureResources.dot"

