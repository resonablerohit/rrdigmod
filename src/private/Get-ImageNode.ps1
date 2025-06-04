function Get-ImageNode {
    [CmdletBinding()]
    param(
        [string[]]$Rows,
        [string]$Type,
        [String]$Name,
        [String]$Label,
        [String]$Style = 'Filled',
        [String]$Shape = 'none',
        [String]$FillColor = 'White'
    )

    $RootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $IconPath = Join-Path $RootPath 'icons'

    $TR = ''
    $flag = $true
    foreach ($r in $Rows) {
        if ($flag) {
            $TR += "<TR><TD ALIGN='center' COLSPAN='2'><B><FONT POINT-SIZE='10'>$r</FONT></B></TD></TR>"
            $flag = $false
        } else {
            $parts = $r.Split('/', 2)
            if ($parts.Count -eq 2) {
                $TR += "<TR><TD ALIGN='right'><FONT POINT-SIZE='8'>Provider:</FONT></TD><TD ALIGN='left'><FONT POINT-SIZE='8'>$($parts[0])</FONT></TD></TR>"
                $TR += "<TR><TD ALIGN='right'><FONT POINT-SIZE='8'>Type:</FONT></TD><TD ALIGN='left'><FONT POINT-SIZE='8'>$($parts[1])</FONT></TD></TR>"
            } else {
                $TR += "<TR><TD ALIGN='center' COLSPAN='2'><FONT POINT-SIZE='8'>$r</FONT></TD></TR>"
            }
        }
    }

    $SafeType = $Type.ToLower().Replace('/', '_').Replace('.', '')
    $iconFile = Get-ChildItem -Path $IconPath -Recurse -Filter "$SafeType.svg" -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $iconFile) {
        # fallback to generic resource icon
        $iconFile = Get-ChildItem -Path $IconPath -Recurse -Filter "resources.svg" -ErrorAction SilentlyContinue | Select-Object -First 1
    }

    $iconPathForDot = $iconFile.FullName.Replace('\', '/')

    return @"
"$Name" [
    label=<<TABLE BORDER='0' CELLBORDER='0' CELLPADDING='1'>
        <TR><TD ALIGN='CENTER' COLSPAN='2'><IMG SRC="$iconPathForDot"/></TD></TR>
        $TR
    </TABLE>>;
    fillcolor="$FillColor";
    shape="$Shape";
    style="$Style";
    penwidth="1";
    fontname="Courier New"
]
"@
}

