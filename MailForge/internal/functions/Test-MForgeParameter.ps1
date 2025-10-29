function Test-MForgeParameter {
    <#
    .SYNOPSIS
        Validates that either a parameter or a corresponding attribute in template data is present.

    .DESCRIPTION
        Checks if the specified parameter is set in the caller's PSBoundParameters or if the
        corresponding attribute exists in the template data. If neither is present, the function
        throws a warning and stops execution. Useful for ensuring required mail parameters
        (like Subject or RecipientList) are available before sending mails.

    .PARAMETER CallerPSBoundParameters
        Hashtable of parameters (aka PSBoundParameters) passed to the calling function.

    .PARAMETER TemplateData
        The template data object or array to check for the required attribute.

    .PARAMETER KeyParamName
        The name of the parameter to check in PSBoundParameters.

    .PARAMETER KeyAttrName
        The name of the attribute to check in TemplateData.

    .EXAMPLE
        Test-MForgeParameter -CallerPSBoundParameters $PSBoundParameters -TemplateData $TemplateData `
            -KeyParamName 'Subject' -KeyAttrName 'SubjectAttr'
        Validates that either the Subject parameter is set or the SubjectAttr exists in the data.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $CallerPSBoundParameters,
        [Parameter(Mandatory = $true)]
        $TemplateData,
        [Parameter(Mandatory = $true)]
        $KeyParamName,
        [Parameter(Mandatory = $true)]
        $KeyAttrName
    )
    $templateDataNotContainsKeyAttribute = ($TemplateData.$KeyAttrName | Measure-Object | Select-Object -ExpandProperty Count ) -eq 0
    if (-not $CallerPSBoundParameters.ContainsKey($KeyParamName) -and $KeyAttrName -and $templateDataNotContainsKeyAttribute) {
        Stop-PSFFunction -Level Warning -Message "Neither param '$KeyParamName' is set nor does TemplateData contains the Attribute '$KeyAttrName' not found in data, please check your input." -EnableException $true
    }
}