@{
    # Module Info
    RootModule        = 'rrdigmod.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b2ac38b9-0c45-4d71-b78d-d4a9652fe250'
    Author            = 'Rohit Raj'
    Copyright         = '(c) 2025 Rohit Raj. All rights reserved.'
    Description       = 'RrDigMod: Visualize Azure infrastructure topology in SVG using Graphviz and updated Azure icon sets.'
    PowerShellVersion = '5.1'

    # Script Files
    ScriptsToProcess  = @()

    # Nested Modules
    NestedModules     = @()

    # Functions
    FunctionsToExport = @(
        'Export-RrDigMod'
    )

    # Cmdlets / Variables / Aliases
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    # Private Functions (in src/private)
    PrivateData = @{
        PSData = @{
            Tags         = @('Azure', 'Topology', 'Graphviz', 'SVG', 'ARM', 'Cloud', 'Visualization')
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ProjectUri   = 'https://github.com/resonablerohit/rrdigmod'
            IconUri      = 'https://raw.githubusercontent.com/resonablerohit/rrdigmod/main/assets/rrdigmod-logo.png'
            ReleaseNotes = 'Initial version of RrDigMod with full SVG support, updated icons, enhanced Azure service coverage and network mappings.'
        }
    }

    # File Lists
    FileList = @(
        'rrdigmod.psm1',
        'src/public/Export-RrDigMod.ps1',
        'src/private/ConvertFrom-ARM.ps1',
        'src/private/ConvertFrom-Network.ps1',
        'src/private/ConvertTo-DOTLanguage.ps1',
        'src/private/Get-ASCIIArt.ps1',
        'src/private/Get-DOTExecutable.ps1',
        'src/private/Get-ImageLabel.ps1',
        'src/private/Get-ImageNode.ps1',
        'src/private/Get-TenantDiagrams.ps1',
        'src/private/Images.ps1',
        'src/private/Remove-SpecialChars.ps1',
        'src/private/Test-AzLogin.ps1',
        'src/private/Write-CustomHost.ps1'
    )
}

