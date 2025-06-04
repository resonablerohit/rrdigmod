function Get-DOTExecutable {
    [CmdletBinding()]
    param ()

    $dotExeName = if ($IsWindows) { "dot.exe" } else { "dot" }

    # 1. Check standard environment paths
    $dotPath = Get-Command $dotExeName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1

    if ($dotPath) {
        Write-Verbose "✅ Found 'dot' in PATH: $dotPath"
        return (Get-Item $dotPath)
    }

    # 2. Check common Graphviz installation paths
    $defaultPaths = @()
    if ($IsWindows) {
        $defaultPaths += "C:\Program Files\Graphviz\bin\dot.exe"
        $defaultPaths += "C:\Program Files (x86)\Graphviz\bin\dot.exe"
    }
    elseif ($IsLinux) {
        $defaultPaths += "/usr/bin/dot"
        $defaultPaths += "/usr/local/bin/dot"
        $defaultPaths += "/snap/bin/dot"
    }
    elseif ($IsMacOS) {
        $defaultPaths += "/opt/homebrew/bin/dot"
        $defaultPaths += "/usr/local/bin/dot"
    }

    foreach ($path in $defaultPaths) {
        if (Test-Path $path) {
            Write-Verbose "✅ Found 'dot' in default location: $path"
            return (Get-Item $path)
        }
    }

    # 3. If not found, display guidance
    Write-Error "'Graphviz' is not installed or 'dot' is not in the system PATH. Please install Graphviz from https://graphviz.org/download/ and ensure 'dot' is accessible."
    return $null
}

