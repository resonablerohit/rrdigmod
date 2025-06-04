$script:images = @{}

function Initialize-ImageMappings {
    [CmdletBinding()]
    param (
        [string]$IconDirectory = "$PSScriptRoot/../../icons"
    )

    if (-not (Test-Path $IconDirectory)) {
        throw "Icon directory not found at $IconDirectory"
    }

    Write-Verbose "🔄 Initializing image mappings from: $IconDirectory"

    Get-ChildItem -Path $IconDirectory -Recurse -Include *.svg | ForEach-Object {
        $iconPath = $_.FullName
        $iconName = $_.BaseName.ToLower()

        # Normalize icon name to match ARM types
        $normalizedKey = $iconName -replace ' ', '' -replace '_', '/'
        $script:images[$normalizedKey] = $iconPath
    }

    # Add fallback icons
    if (-not $script:images.ContainsKey("resources")) {
        $fallback = Get-ChildItem -Path $IconDirectory -Recurse -Include "resources.svg" | Select-Object -First 1
        if ($fallback) {
            $script:images["resources"] = $fallback.FullName
        }
    }
}

# Example Usage:
# Initialize-ImageMappings -IconDirectory "/root/rrdigmod/icons"
# $iconPath = $script:images["microsoft.compute/virtualmachines"]

