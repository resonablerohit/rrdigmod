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
            Write-CustomHost "Analyzing network topology for resource group: `'$Target`'" -Indentation 1 -color Cyan

            try {
                $location = (Get-AzResourceGroup -Name $ResourceGroup -Verbose:$false).Location
                $networkWatcher = Get-AzNetworkWatcher -Location $location -ErrorAction SilentlyContinue -Verbose:$false
            } catch {
                Write-CustomHost "Failed to get location or network watcher for: $ResourceGroup" -Color Red
                continue
            }

            if (-not $networkWatcher) {
                Write-CustomHost "Network watcher not found for '$ResourceGroup'" -Indentation 2 -Color Yellow
                continue
            }

            $Topology = Get-AzNetworkWatcherTopology -NetworkWatcher $networkWatcher -TargetResourceGroupName $ResourceGroup -Verbose:$false 
            $resources = $Topology.Resources

            if (-not $resources) {
                Write-CustomHost "No network-related resources found in: $ResourceGroup" -Indentation 2 -Color Yellow
                continue
            }

            $data = @()
            $SkipMsgFlag = $true

            $data += $resources | 
            Select-Object @{n='from'; e={$_.name}},
                          @{n='fromcateg'; e={(Get-AzResource -ResourceId $_.id -ErrorAction SilentlyContinue -Verbose:$false).ResourceType}},
                          Associations,
                          @{n='to'; e={ ($_.AssociationText | ConvertFrom-Json) | Select-Object name, AssociationType, resourceID }} |
            Where-Object { $_.fromcateg -and ($_.fromcateg.split("/").count -le ($CategoryDepth + 1)) } |
            ForEach-Object {
                if ($_.to) {
                    foreach ($to in $_.to) {
                        if ($to.ResourceID -like "*$ResourceGroup*") {
                            $fromCateg = $_.fromcateg
                            $r = $rank[$fromCateg]
                            [PSCustomObject]@{
                                fromcateg   = $fromCateg
                                from        = $_.from
                                to          = $to.name
                                toCateg     = (Get-AzResource -ResourceId $to.resourceID -ErrorAction SilentlyContinue).ResourceType
                                association = $to.associationType
                                rank        = if ($r) { $r } else { 9999 }
                            }
                        } else {
                            if ($SkipMsgFlag) {
                                Write-CustomHost "Skipping external associations not in RG '$ResourceGroup'" -Indentation 3 -color Yellow
                                $SkipMsgFlag = $false
                            }
                            Write-CustomHost "External ID: $($to.ResourceID)" -Indentation 4 -color Yellow
                        }
                    }
                } else {
                    $r = $rank[$_.fromcateg]
                    [PSCustomObject]@{
                        fromcateg   = $_.fromcateg
                        from        = $_.from
                        to          = ''
                        toCateg     = ''
                        association = ''
                        rank        = if ($r) { $r } else { 9999 }
                    }
                }
            } | Sort-Object rank

            [PSCustomObject]@{
                Type      = $TargetType
                Name      = $Target
                Resources = $data | Where-Object $scriptblock
            }
        }
    }
    
    end {}
}

