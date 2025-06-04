function ConvertFrom-Network {
    [CmdletBinding()]
    param (
        [string[]] $Targets,
        [ValidateSet('Azure Resource Group')]
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
        }

        $Excluded_NetworkObjects = @(
            "*Microsoft.Network/virtualNetworks*",
            "*Microsoft.Network/virtualNetworks/subnets*",
            "*Microsoft.Network/networkSecurityGroups*"
        )

        if ($ExcludeTypes) {
            $Excluded_NetworkObjects += $ExcludeTypes
        }

        $scriptblock = [scriptblock]::Create(
            $Excluded_NetworkObjects.ForEach({
                '$_.fromcateg -NotLike "{0}" -and $_.tocateg -NotLike "{0}"' -f $_
            }) -join ' -and '
        )
    }

    process {
        foreach ($Target in $Targets) {
            $ResourceGroup = $Target
            Write-CustomHost "🌐 Gathering network topology for RG: '$ResourceGroup'" -Indentation 1 -Color Cyan

            try {
                $location = (Get-AzResourceGroup -Name $ResourceGroup -Verbose:$false).Location
                $networkWatcher = Get-AzNetworkWatcher -Location $location -ErrorAction SilentlyContinue
            } catch {
                Write-CustomHost "❌ Failed to locate Network Watcher for RG: '$ResourceGroup'" -Indentation 2 -Color Red
                continue
            }

            if ($networkWatcher) {
                Write-CustomHost "🔎 Network watcher found: '$($networkWatcher.Name)'" -Indentation 2 -Color Green
                $Topology = Get-AzNetworkWatcherTopology -NetworkWatcher $networkWatcher -TargetResourceGroupName $ResourceGroup -Verbose:$false
                $Resources = $Topology.Resources
            } else {
                Write-CustomHost "⚠ No Network Watcher in region. Skipping '$ResourceGroup'" -Indentation 2 -Color Yellow
                continue
            }

            if (!$Resources) {
                Write-CustomHost "⚠ No network resources found. Skipping." -Indentation 2 -Color Yellow
                continue
            }

            $data = @()
            $skipExternalMsgShown = $false

            $data += $Resources | ForEach-Object {
                $from = $_.Name
                $fromcateg = (Get-AzResource -ResourceId $_.Id -ErrorAction SilentlyContinue).ResourceType
                $rankValue = $rank[$fromcateg] | ForEach-Object { $_ } | DefaultIfEmpty 9999

                $associations = $_.AssociationText | ConvertFrom-Json

                if ($associations) {
                    foreach ($assoc in $associations) {
                        $assocRGMatch = $assoc.ResourceId -match "/resourceGroups/$ResourceGroup"
                        if ($assocRGMatch) {
                            $to = $assoc.name
                            $toCateg = (Get-AzResource -ResourceId $assoc.ResourceId -ErrorAction SilentlyContinue).ResourceType
                            [PSCustomObject]@{
                                from        = $from
                                fromcateg   = $fromcateg
                                to          = $to
                                tocateg     = $toCateg
                                association = $assoc.AssociationType
                                rank        = $rankValue
                            }
                        } else {
                            if (-not $skipExternalMsgShown) {
                                Write-CustomHost "⚠ Skipping resources outside RG '$ResourceGroup'" -Indentation 3 -Color Yellow
                                $skipExternalMsgShown = $true
                            }
                            Write-CustomHost "$($assoc.ResourceId)" -Indentation 4 -Color Yellow
                        }
                    }
                } else {
                    [PSCustomObject]@{
                        from        = $from
                        fromcateg   = $fromcateg
                        to          = ''
                        tocateg     = ''
                        association = ''
                        rank        = $rankValue
                    }
                }
            } | Where-Object $scriptblock | Sort-Object rank

            [PSCustomObject]@{
                Type      = $TargetType
                Name      = $ResourceGroup
                Resources = $data
            }
        }
    }
}

