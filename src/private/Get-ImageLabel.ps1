function Get-ImageLabel {
    [CmdletBinding()]
    param (
        [string]$Type,
        [string]$Row1,
        [string]$Row2,
        [string]$Row3,
        [string]$Row4
    )

    $rows = @($Row1, $Row2, $Row3, $Row4) | Where-Object { $_ -ne $null -and $_ -ne "" }

    $labelRows = foreach ($r in $rows) {
        "<TR><TD ALIGN='CENTER' COLSPAN='2'><FONT POINT-SIZE='10'>$r</FONT></TD></TR>"
    }

    $table = @(
        "<TABLE BORDER='0' CELLBORDER='0' CELLPADDING='1'>"
        "<TR><TD ALIGN='CENTER' COLSPAN='2'><B><FONT POINT-SIZE='11'>$Type</FONT></B></TD></TR>"
        $labelRows
        "</TABLE>"
    ) -join "`n"

    return $table
}

