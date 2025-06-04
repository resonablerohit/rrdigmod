function Test-AzLogin {
    [CmdletBinding()]
    param()

    try {
        # Attempt to retrieve the current Azure context
        $context = Get-AzContext -ErrorAction Stop

        if ($null -eq $context.Account) {
            Write-CustomHost "⚠️  No Azure account found in current context." -Color Yellow
            return $false
        }

        if ($null -eq (Get-AzSubscription -ErrorAction Stop)) {
            Write-CustomHost "⚠️  Azure context is not linked to an active subscription." -Color Yellow
            return $false
        }

        Write-CustomHost "✅ Azure login and context verified: $($context.Account.Id)" -Color Green
        return $true
    }
    catch {
        Write-CustomHost "❌ Not logged in to Azure. Please run 'Connect-AzAccount'." -Color Red
        return $false
    }
}

