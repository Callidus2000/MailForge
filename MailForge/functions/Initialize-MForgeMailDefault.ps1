function Initialize-MForgeMailDefault {
    <#
    .SYNOPSIS
    Initializes default values for mail sending with MailForge.

    .DESCRIPTION
    Sets default configuration for sending emails with Send-MailKitMessage. The values are stored
    as PSFramework configuration and can be used for SMTP server, port, sender, recipient lists,
    CC/BCC, and other settings. Configuration is done via the provided parameters and saved in the
    specified ConfigScope. Passing an empty string or $null as a parameter will remove the
    corresponding setting.

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

    .PARAMETER ConfigScope
    The configuration scope in which the values are stored. Allowed values:
    Environment, EnvironmentSimple, FileSystem, FileUserLocal, FileUserShared, SystemDefault,
    SystemMandatory, UserDefault, UserMandatory.

    .EXAMPLE
    Initialize-MForgeMailDefault -SMTPServer 'smtp.example.com' -Port 587 -From 'user@example.com'
    -Credential (Get-Credential) -ConfigScope 'UserDefault'

    Initializes the default values for mail sending with the specified parameters.
    #>
    [CmdletBinding()]
    param (
        [pscredential]$Credential,
        [string]$SMTPServer,
        [int]$Port,
        $From, # MailboxAddress
        $RecipientList, # InternetAddressList
        $CCList, # InternetAddressList
        $BCCList, # InternetAddressList
        [boolean]$UseSecureConnectionIfAvailable,
        [ValidateSet("Environment", "EnvironmentSimple", "FileSystem", "FileUserLocal", "FileUserShared", "SystemDefault", "SystemMandatory", "UserDefault", "UserMandatory")]
        [string]$ConfigScope = "UserDefault"
    )
    $newDefaults=$PSBoundParameters | ConvertTo-PSFHashtable -Exclude 'ConfigScope'
    foreach ($key in $newDefaults.Keys) {
        if (-not [string]::IsNullOrEmpty($newDefaults[$key])) {
            Write-PSFMessage -Level Verbose -Message "Setting default for $key to $($newDefaults[$key]) for scope $ConfigScope"
            Set-PSFConfig -Module 'MailForge' -Name "MailKitDefaults.$key" -Value $newDefaults[$key] -Description "Default value for $key when sending mails with Send-MailKitMessage." -AllowDelete -PassThru| Register-PSFConfig -Scope $ConfigScope
        }else{
            Write-PSFMessage -Level Verbose -Message "Removing default for $key for scope $ConfigScope"
            Unregister-PSFConfig -Module 'MailForge' -Name "MailKitDefaults.$key" -Scope $ConfigScope #-ErrorAction SilentlyContinue
            Remove-PSFConfig -Module 'MailForge' -Name "MailKitDefaults.$key" -Confirm:$false #-ErrorAction SilentlyContinue
        }
    }
    # Set-PSFConfig -Module 'MailForge' -Name 'MailKitDefaults.UseSecureConnectionIfAvailable' -Value $true -Initialize -Validation 'bool' -Description "Whether to use a secure connection if available by default when sending mails."
}