function Send-MForgeMail {
    <#
    .SYNOPSIS
    Sends an email using MailForge with template support and configurable mail parameters.

    .DESCRIPTION
    This function sends an email using MailForge. It supports sending via a named template,
    template file, or a temporary template. All mail parameters from Initialize-MForgeMailDefault
    can be optionally provided. The function allows flexible template usage and mail configuration.

    The following parameters can be set as defaults using Initialize-MForgeMailDefault:
    Credential, SMTPServer, Port, From, RecipientList, CCList, BCCList, UseSecureConnectionIfAvailable,
    ConfigScope.

    .PARAMETER Credential
    Credentials for authenticating with the SMTP server.

    .PARAMETER SMTPServer
    The name or address of the SMTP server.

    .PARAMETER Port
    The port to use for connecting to the SMTP server.

    .PARAMETER From
    The sender address (MailboxAddress).

    .PARAMETER RecipientList
    List of recipient addresses (InternetAddressList).

    .PARAMETER CCList
    List of CC recipient addresses (InternetAddressList).

    .PARAMETER BCCList
    List of BCC recipient addresses (InternetAddressList).

    .PARAMETER UseSecureConnectionIfAvailable
    Indicates whether to use a secure connection if available.

    .PARAMETER Subject
    The subject of the email.

    .PARAMETER TemplateParameters
    Parameters to pass to the template for mail generation. Mandatory.

    .PARAMETER TemplateName
    The name of the existing template to use. Mandatory in ParameterSet 'ByName'.

    .PARAMETER TemplateFile
    The path to the template file to use. Mandatory in ParameterSet 'ByFile'.

    .EXAMPLE
    Send-MForgeMail -TemplateName 'MyTemplate' -TemplateParameters $params

    Sends an email using the template 'MyTemplate' and the provided parameters.
    #>
    [CmdletBinding()]
    param (
        # Optional parameters from Initialize-MForgeMailDefault
        [pscredential]$Credential,
        [string]$SMTPServer,
        [int]$Port,
        $From, # MailboxAddress
        $RecipientList, # InternetAddressList
        $CCList, # InternetAddressList
        $BCCList, # InternetAddressList
        [boolean]$UseSecureConnectionIfAvailable,
        [string]$Subject,

        # Mandatory parameters
        [Parameter(Mandatory = $true)]
        $TemplateParameters,

        # ParameterSet ByName
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [string]$TemplateName,

        # ParameterSet ByFile
        [Parameter(Mandatory = $true, ParameterSetName = 'ByFile')]
        [string]$TemplateFile
    )
    $sendMailParams = Get-MForgeMailDefault -CurrentPSBoundParameters $PSBoundParameters
    if ($PSCmdlet.ParameterSetName -eq 'ByFile') {
         $templateName=Register-MForgeTemplate -TemplateFile $TemplateFile -Temporary
    }
    $template = Get-PSMDTemplate $TemplateName
    if(-not $template){
        Stop-PSFFunction -Level Warning -Message "Template $TemplateName not found"
        return
    }
    $templateResults = Invoke-PSMDTemplate -TemplateName $TemplateName -Parameters $TemplateParameters -GenerateObjects

    switch -Regex (($template).Tags | Join-String -Separator ',') {
        'MD' {
            Write-PSFMessage "Konvertiere MarkDown nach HTML"
            $mdContent = $templateResults | Select-Object -First 1 -ExpandProperty Content
            $sendMailParams.HtmlBody = ($mdContent | ConvertFrom-Markdown).Html
        }
        'HTML' {
            Write-PSFMessage "Erzeuge HTML aus dem Template"
            $sendMailParams.HtmlBody = $templateResults | Select-Object -First 1 -ExpandProperty Content
        }
    }
    Write-PSFMessage "SendMail-Params: $($sendMailParams | ConvertTo-Json -Compress)"
    Invoke-PSFProtectedCommand -Action "Sending Mail to $($sendMailParams.RecipientList)" -ScriptBlock {
        Send-MailKitMessage @sendMailParams
    }
    if ($PSCmdlet.ParameterSetName -eq 'ByFile') {
        Remove-PSMDTemplate -TemplateName $TemplateName -Confirm:$false -ErrorAction SilentlyContinue
    }
}