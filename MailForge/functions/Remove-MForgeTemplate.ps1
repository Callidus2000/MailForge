function Remove-MForgeTemplate {
    <#
    .SYNOPSIS
    Removes MailForge template objects by name or cleans up orphaned temporary templates.

    .DESCRIPTION
    This function removes MailForge template objects. You can either specify a template name to remove a specific template, or use the -Orphan switch to remove all orphaned temporary templates (those tagged as 'TemporaryMForgeTemplate').
    The parameters -TemplateName and -Orphan are mutually exclusive and must be used in separate parameter sets.

    .PARAMETER TemplateName
    The name of the MailForge template to remove. Only templates registered via Register-MForgeTemplate can be removed. Mandatory when using the ByName parameter set.

    .PARAMETER Orphan
    Removes all orphaned temporary templates. Mandatory when using the Orphan parameter set.

    .EXAMPLE
    Remove-MForgeTemplateOrphan -TemplateName "WelcomeMail"

    Removes the template named "WelcomeMail".

    .EXAMPLE
    Remove-MForgeTemplateOrphan -Orphan

    Removes all orphaned temporary MailForge templates.

    #>


    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [PsfArgumentCompleter('MForgeTemplateNames')]
        [PsfValidateSet(TabCompletion = 'MForgeTemplateNames')]
        $TemplateName,
        [Parameter(ParameterSetName = 'Orphan', Mandatory = $true)]
        [switch]$Orphan
    )
    switch ($PSCmdlet.ParameterSetName) {
        'Orphan' {
            Get-PSMDTemplate -ErrorAction SilentlyContinue | Where-Object {
                $_.Tags -contains 'TemporaryMForgeTemplate'
            } | ForEach-Object {
                Write-PSFMessage "Removing orphaned temporary template $($_.Name)" -Level Host
                Remove-PSMDTemplate -TemplateName $_.Name -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
        'ByName' {
            Remove-PSMDTemplate -TemplateName $TemplateName
        }
    }
}