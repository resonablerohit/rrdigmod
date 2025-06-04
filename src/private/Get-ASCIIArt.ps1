function Get-ASCIIArt {
    [CmdletBinding()]
    param (
        [string]$Theme = 'Default',
        [switch]$Colored
    )

    $asciiArt = @"

  ______     ______     ______   ______     __  __     ______     ______    
 /\  == \   /\  ___\   /\__  _\ /\  ___\   /\ \_\ \   /\  ___\   /\  == \   
 \ \  __<   \ \  __\   \/_/\ \/ \ \  __\   \ \____ \  \ \  __\   \ \  __<   
  \ \_\ \_\  \ \_____\    \ \_\  \ \_____\  \/\_____\  \ \_____\  \ \_\ \_\ 
   \/_/ /_/   \/_____/     \/_/   \/_____/   \/_____/   \/_____/   \/_/ /_/ 
                                                                            

"@

    $poweredBy = "rrdigmod :: Azure Diagram Generator (Enhanced SVG Version)"
    $website   = "https://github.com/resonablerohit/rrdigmod"

    if ($Colored) {
        Write-Host $asciiArt -ForegroundColor Cyan
        Write-Host $poweredBy -ForegroundColor Yellow
        Write-Host $website -ForegroundColor DarkCyan
    }
    else {
        Write-Host $asciiArt
        Write-Host $poweredBy
        Write-Host $website
    }
}

