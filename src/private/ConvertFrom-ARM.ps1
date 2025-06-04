function ConvertFrom-ARM {
    [CmdletBinding()]
    param (
        [string[]] $Targets,
        [ValidateSet('Azure Resource Group', 'File', 'Url')]
        [string] $TargetType = 'Azure Resource Group',
        [int] $CategoryDepth = 1,
        [string[]] $ExcludeTypes
    )

    begin {
        $rank = @{
            "Microsoft.Network/publicIPAddresses"     = 1
            "Microsoft.Network/loadBalancers"         = 2
            "Microsoft.Network/virtualNetworks"       = 3 
            "Microsoft.Network/networkSecurityGroups" = 4
            "Microsoft.Network/networkInterfaces"     = 5
            "Microsoft.Compute/virtualMachines"       = 6
            "Microsoft.ManagedIdentity/userAssignedIdentities" = 7
            "Microsoft.KeyVault/vaults"               = 8
            "Microsoft.Insights/components"           = 9
        }

        # Build exclusion logic
        $Excluded_ARMObjects = @(
            "Microsoft.Network/virtualNetworks*",
            "Microsoft.Network/virtualNetworks/subnets*",
            "Microsoft.Network/networkSecurityGroups*"
        )

        if ($ExcludeTypes) {
            $Excluded_ARMObjects += $ExcludeTypes
        }

        $conditionScript = [scriptblock]::Create(
            $Excluded_ARMObjects.ForEach({
                '$_.fromcateg -NotLike "{0}" -and $_.tocateg -NotLike "{0}"' -f $_
            }) -join ' -and '
        )
    }

    process {
        foreach ($Target in $Targets) {
            $temp_armtemplate = New-TemporaryFile

            switch ($TargetType) {
                'Azure Resource Group' {
                    Write-CustomHost "🔍 Exporting ARM for Resource Group: '$Target'" -Indentation 1 -Color Cyan
                    $template = (Export-AzResourceGroup -ResourceGroupName $Target -SkipAllParameterization -Force -Path $temp_armtemplate -WarningAction SilentlyContinue).Path
                }
                'File' {
                    Write-CustomHost "📂 Using local ARM template: '$Target'" -Indentation 1 -Color Green
                    $template = $Target
                }
                'Url' {
                    Write-CustomHost "🌐 Downloading ARM template from URL: '$Target'" -Indentation 1 -Color Yellow
                    Invoke-WebRequest -Uri $Target -OutFile $temp_armtemplate -UseBasicParsing
                    $template = $temp_armtemplate
                }
            }

            Write-CustomHost "🛠 Parsing resources..." -Indentation 2 -Color Green
            $arm = Get-Content -Path $template | ConvertFrom-Json
            $resources = $arm.resources | Where-Object $conditionScript

            if (!$resources) {
                Write-CustomHost "⚠ No eligible resources found for $Target. Skipping." -Indentation 2 -Color DarkYellow
                continue
            }

            Write-CustomHost "✅ Found $($resources.Count) resources. Cleaning up template." -Indentation 2 -Color Green
            Remove-Item $template -Force

            # Dependency extraction
            $data = @()
            $data += $resources |
            Where-Object { $_.type.ToString().Split("/").Count -le ($CategoryDepth + 1) } |
            ForEach-Object {
                $dependsOn = $_.dependsOn
                $resourceType = $_.type.ToString()
                $resourceName = $_.name.ToString()
                $rankValue = $rank[$resourceType] | ForEach-Object { $_ } | DefaultIfEmpty 9999

                if ($dependsOn) {
                    foreach ($dependency in $dependsOn) {
                        [PSCustomObject]@{
                            from        = $resourceName
                            fromcateg   = $resourceType
                            to          = $dependency -replace "^.*?,\s*'(.*?)'.*$", '$1'
                            tocateg     = $dependency -replace "^.*?'(.*?)'.*$", '$1' -replace "/[^/]+$", ''
                            isdependent = $true
                            rank        = $rankValue
                        }
                    }
                }
                else {
                    [PSCustomObject]@{
                        from        = $resourceName
                        fromcateg   = $resourceType
                        to          = ''
                        tocateg     = ''
                        isdependent = $false
                        rank        = $rankValue
                    }
                }
            } | Sort-Object rank

            [PSCustomObject]@{
                Type      = $TargetType
                Name      = $Target
                Resources = $data | Where-Object $conditionScript
            }
        }
    }
}

