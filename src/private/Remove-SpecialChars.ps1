function Remove-SpecialChars {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$String,

        [string]$ReplacementChar = "_",

        [string[]]$SpecialChars = @(
            " ", "`"", "'", "`'", "`;", "`&", "`%", "`$", "`#", "`@", "`!", "`*", "`(", "`)", "`=", "`+", "`|", "`?", "`/", "`\\", "`:", "`<", "`>", "`[", "`]", "`{", "`}", "`~", "`^", "`."
        )
    )

    $result = $String

    foreach ($char in $SpecialChars) {
        $result = $result -replace [regex]::Escape($char), $ReplacementChar
    }

    # Remove multiple consecutive replacement characters
    $result = $result -replace "$([regex]::Escape($ReplacementChar)){2,}", $ReplacementChar

    # Trim leading/trailing replacement chars
    $result = $result.Trim($ReplacementChar)

    return $result
}

