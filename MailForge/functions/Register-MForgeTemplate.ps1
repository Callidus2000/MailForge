function Register-MForgeTemplate {
    <#
    .SYNOPSIS
    Registers a template for MailForge using a file or string, with custom name, type, and store.

    .DESCRIPTION
    This function registers a template for MailForge. You can provide the template as a file
    or as a string. The template is registered under the specified name, in the chosen store,
    with the given version. The TemplateType parameter allows tagging the template as String,
    MD5, or HTML for later identification and processing.

    .PARAMETER TemplateFile
    The path to the template file to be registered. Used in file-based parameter sets.

    .PARAMETER TemplateString
    The template content as a string. Used in string-based parameter sets.

    .PARAMETER TemplateName
    The name under which the template will be registered.

    .PARAMETER Temporary
    If set, registers the template as temporary with a generated name.

    .PARAMETER OutStore
    The store in which the template will be saved. Default is 'Default'.

    .PARAMETER Version
    The version of the template. Default is '1.0.0'.

    .PARAMETER TemplateType
    The type of the template (String, MD5, HTML). Used for tagging and identification.

    .EXAMPLE
    Register-MForgeTemplate -TemplateFile 'template.ps1' -TemplateName 'MyTemplate' -TemplateType 'HTML'

    Registers the template file as 'MyTemplate' in the default store with type 'HTML'.

    .EXAMPLE
    Register-MForgeTemplate -TemplateString $content -TemplateName 'MyTemplate' -TemplateType 'String'

    Registers the template from string content as 'MyTemplate' in the default store with type 'String'.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByNameAndFile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TemporaryByFile')]
        [PSFFile]$TemplateFile,
        [Parameter(Mandatory = $true, ParameterSetName = 'ByNameAndString')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TemporaryByString')]
        [string]$TemplateString,
        [Parameter(Mandatory = $true, ParameterSetName = 'ByNameAndString')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByNameAndFile')]
        [string]$TemplateName,
        [Parameter(Mandatory = $true, ParameterSetName = 'TemporaryByString')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TemporaryByFile')]
        [switch]$Temporary,
        $OutStore = "Default",
        [string]$Version = "1.0.0",
        [Parameter(Mandatory = $true, ParameterSetName = 'TemporaryByString')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByNameAndString')]
        [Parameter(Mandatory = $false, ParameterSetName = 'TemporaryByFile')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ByNameAndFile')]
        [ValidateSet("TXT", "HTML", "MD")]
        [string]$TemplateType
    )
    if ($TemplateString) {
        $tempFile = [System.IO.Path]::GetTempFileName()
        Write-PSFMessage "Creating temporary file $tempFile for template string"
        $TemplateFile = $tempFile
        Set-Content -Path $tempFile -Value $TemplateString -Encoding UTF8 -WhatIf:$false
    }
    $fileObj = Get-Item -Path $TemplateFile
    if ($TemplateString) {
        $extension = $TemplateType.ToUpper()
    }
    else {
        $extension = $fileObj.Extension.ToUpper() -replace '\.'

    }
    $tags = @($extension,'MailForge')
    if ($Temporary) {
        $TemplateName = "MForgeTempTemplate_$([Guid]::NewGuid().ToString())"
        $tags += "TemporaryMForgeTemplate"
        Write-PSFMessage "Registering temporary template $TemplateName from file $TemplateFile"
        # New-PSMDTemplate -TemplateName $TemplateName -Outstore $OutStore -FilePath $TemplateFile -Version $Version -Force -Tags $tags
        # Return the generated template name
        $TemplateName
    }
    # else {
    New-PSMDTemplate -TemplateName $TemplateName -Outstore $OutStore -FilePath $TemplateFile -Version $Version -Force -Tags $tags
    # }
    if ($TemplateString) {
        Write-PSFMessage "Cleaning up temporary file $tempFile"
        remove-item -Path $tempFile -ErrorAction SilentlyContinue  -WhatIf:$false
    }
}