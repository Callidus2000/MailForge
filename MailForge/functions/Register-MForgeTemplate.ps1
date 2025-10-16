function Register-MForgeTemplate {
    <#
    .SYNOPSIS
    Registers a template for MailForge using the specified file and name.

    .DESCRIPTION
    This function registers a template for MailForge. The template file and name are mandatory
    parameters. The template is stored in the specified store with the given version and tagged
    according to its file extension.

    .PARAMETER TemplateFile
    The path to the template file to be registered.

    .PARAMETER TemplateName
    The name under which the template will be registered.

    .PARAMETER OutStore
    The store in which the template will be saved. Default is 'Default'.

    .PARAMETER Version
    The version of the template. Default is '1.0.0'.

    .EXAMPLE
    Register-MForgeTemplate -TemplateFile 'template.ps1' -TemplateName 'MyTemplate'

    Registers the template 'template.ps1' as 'MyTemplate' in the default store with version 1.0.0.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSFFile]$TemplateFile,
        [Parameter(Mandatory=$true, ParameterSetName='ByName')]
        [string]$TemplateName,
        [Parameter(Mandatory=$true, ParameterSetName='Temporary')]
        [switch]$Temporary,
        $OutStore = "Default",
        [string]$Version = "1.0.0"
    )
    $fileObj=Get-Item -Path $TemplateFile
    $extension=$fileObj.Extension.ToUpper() -replace '\.'
    $tags=@($extension)
    if ($PSCmdlet.ParameterSetName -eq 'Temporary') {
        $TemplateName = "MForgeTempTemplate_$([Guid]::NewGuid().ToString())"
        $tags+= "TemporaryMForgeTemplate"
        Write-PSFMessage "Registering temporary template $TemplateName from file $TemplateFile"
        New-PSMDTemplate -TemplateName $TemplateName -Outstore $OutStore -FilePath $TemplateFile -Version $Version -Force -Tags $tags
        return $TemplateName
    } else {
        New-PSMDTemplate -TemplateName $TemplateName -Outstore $OutStore -FilePath $TemplateFile -Version $Version -Force -Tags $tags
    }
}