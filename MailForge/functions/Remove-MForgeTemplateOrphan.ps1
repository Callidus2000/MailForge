function Remove-MForgeTemplateOrphan {
    <#
    .SYNOPSIS
    Removes orphaned MailForge template objects.

    .DESCRIPTION
    This function removes MailForge template objects that are no longer associated with any
    active configuration or usage. Use this to clean up orphaned templates and maintain a tidy
    environment.

    .EXAMPLE
    Remove-MForgeTemplateOrphan

    Removes all orphaned MailForge template objects.
    #>

    [CmdletBinding()]
    param (

    )
    Get-PSMDTemplate -ErrorAction SilentlyContinue | Where-Object { $_.Tags -contains 'TemporaryMForgeTemplate'}|ForEach-Object {
        Write-PSFMessage "Removing orphaned temporary template $($_.Name)" -Level Host
        Remove-PSMDTemplate -TemplateName $_.Name -Confirm:$false -ErrorAction SilentlyContinue
    }
}