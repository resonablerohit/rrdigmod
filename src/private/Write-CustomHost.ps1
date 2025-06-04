function Write-CustomHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $String,

        [int] $Indentation = 0,

        [ValidateSet('Black','Blue','Cyan','DarkBlue','DarkCyan','DarkGray','DarkGreen','DarkMagenta','DarkRed','DarkYellow','Gray','Green','Magenta','Red','White','Yellow')]
        [string] $Color = 'White',

        [switch] $AddTime
    )

    $prefix = ''
    if ($Indentation -gt 0) {
        $prefix = (' ' * ($Indentation * 2))
    }

    $timestamp = ''
    if ($AddTime) {
        $timestamp = "[{0}] " -f (Get-Date -Format 'HH:mm:ss')
    }

    Write-Host "$timestamp$prefix$String" -ForegroundColor $Color
}

