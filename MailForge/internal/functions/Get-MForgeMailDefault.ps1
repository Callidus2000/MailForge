function Get-MForgeMailDefault {
    <#
    .SYNOPSIS
    Determines the mail parameters configurable for MailForge from the provided parameters.

    .DESCRIPTION
    This function checks which parameters for mail sending in Initialize-MForgeMailDefault are
    configurable and whether they were passed in the calling context. The found values are
    collected in a hashtable and returned.

    .PARAMETER CurrentPSBoundParameters
    The parameters passed from the calling context (equivalent to $PSBoundParameters).

    .EXAMPLE
    $defaults = Get-MForgeMailDefault -CurrentPSBoundParameters $PSBoundParameters

    Returns a hashtable with all configured mail parameters.
    #>
    [CmdletBinding()]
    param (
        $CurrentPSBoundParameters
    )
    # List of configurable parameters from Initialize-MForgeMailDefault
    $configurableParams = @(
        'Credential',
        'SMTPServer',
        'Port',
        'From',
        'RecipientList',
        'CCList',
        'BCCList',
        'UseSecureConnectionIfAvailable'
    )
    $result = @{}
    $overRideParams = $CurrentPSBoundParameters | ConvertTo-PSFHashtable -Include $configurableParams
    foreach ($param in $configurableParams) {
        $default = (Get-PSFConfigValue -FullName "MailForge.MailKitDefaults.$param" -ErrorAction SilentlyContinue)
        if ($default -ne $null) {
            $result[$param] = $default
        }
    }
    if ($overRideParams) {
        foreach ($param in $configurableParams) {
            if ($overRideParams.ContainsKey($param)) {
                $result[$param] = $overRideParams[$param]
            }
        }
    }
    return $result
}