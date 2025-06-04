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
        $RootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $IconsPath = Join-Path $RootPath "icons"
        $IconMap = @{}

        # Build icon mappings from /icons directory
        Get-ChildItem -Path $IconsPath -Recurse -Include *.svg |
        ForEach-Object {
            $key = $_.BaseName.ToLower()
            if (-not $IconMap.ContainsKey($key)) {
                $IconMap[$key] = $_.FullName
            }
        }

        $Excluded_ARMObjects = @(
            "Microsoft.Network/virtualNetworks*",
            "Microsoft.Network/virtualNetworks/subnets*",
            "Microsoft.Network/networkSecurityGroups*"
        )
        if ($ExcludeTypes) {
            $Excluded_ARMObjects += $ExcludeTypes
        }

        $scriptblock = [scriptblock]::Create(
            $Excluded_ARMObjects.ForEach({ '$_.fromcateg -NotLike "{0}" -and $_.tocateg -NotLike "{0}"' -f $_ }) -join ' -and '
        )
    }

    process {
        foreach ($Target in $Targets) {
            $tempFile = New-TemporaryFile

            switch ($TargetType) {
                'Azure Resource Group' {
                    Write-Host "Exporting ARM template for resource group '$Target'" -ForegroundColor Cyan
                    $template = (Export-AzResourceGroup -ResourceGroupName $Target -SkipAllParameterization -Force -Path $tempFile -WarningAction SilentlyContinue -Verbose:$false).Path
                }
                'File' {
                    $template = $Target
                }
                'Url' {
                    $template = $tempFile
                    Invoke-WebRequest -Uri $Target -OutFile $template -Verbose:$false
                }
            }

            $armJson = Get-Content $template -Raw | ConvertFrom-Json
            Remove-Item $tempFile -Force

            $resources = $armJson.resources | Where-Object $scriptblock

            $parsed = @()
            $resources |
            Where-Object { $_.type.ToString().Split("/").Count -le ($CategoryDepth + 1) } |
            ForEach-Object {
                $dep = $_.dependsOn
                if ($dep) {
                    foreach ($d in $dep) {
                        $toSplit = $d.ToString().Replace("[resourceId(", "").Replace(")]", "").Split(",")
                        $toType = $toSplit[0].Replace("'", "").Trim().Split("/")[0..1] -join "/"
                        $toName = $toSplit[1].Replace("'", "").Trim()

                        $iconKey = $_.type.ToString().ToLower()
                        $hasIcon = $IconMap.ContainsKey($iconKey)

                        $parsed += [PSCustomObject]@{
                            from        = $_.name
                            fromcateg   = $_.type
                            to          = $toName
                            tocateg     = $toType
                            isdependent = $true
                            hasicon     = $hasIcon
                        }
                    }
                }
                else {
                    $iconKey = $_.type.ToString().ToLower()
                    $hasIcon = $IconMap.ContainsKey($iconKey)

                    $parsed += [PSCustomObject]@{
                        from        = $_.name
                        fromcateg   = $_.type
                        to          = ''
                        tocateg     = ''
                        isdependent = $false
                        hasicon     = $hasIcon
                    }
                }
            }

            [PSCustomObject]@{
                Type      = $TargetType
                Name      = $Target
                Resources = $parsed | Where-Object $scriptblock
            }
        }
    }
}

