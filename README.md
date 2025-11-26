<!-- PROJECT SHIELDS -->
[![Contributors](https://img.shields.io/github/contributors/Callidus2000/MailForge.svg?style=for-the-badge)](https://github.com/Callidus2000/MailForge/graphs/contributors)
[![Forks](https://img.shields.io/github/forks/Callidus2000/MailForge.svg?style=for-the-badge)](https://github.com/Callidus2000/MailForge/network/members)
[![Stargazers](https://img.shields.io/github/stars/Callidus2000/MailForge.svg?style=for-the-badge)](https://github.com/Callidus2000/MailForge/stargazers)
[![Issues](https://img.shields.io/github/issues/Callidus2000/MailForge.svg?style=for-the-badge)](https://github.com/Callidus2000/MailForge/issues)
[![GPLv3 License](https://img.shields.io/github/license/Callidus2000/MailForge.svg?style=for-the-badge)](https://github.com/Callidus2000/MailForge/blob/master/LICENSE)

# MailForge PowerShell Module

MailForge is a PowerShell module for automating, templating, and sending emails in enterprise environments. It provides advanced features for mass mailing, template management, and integration with modern mail systems, making it ideal for IT automation, notifications, and bulk communications.

## Features

- **Send-MForgeSingleMail:** Send individual or bulk emails using registered or file-based templates, with dynamic parameters.
- **Register-MForgeTemplate:** Create and manage reusable mail templates for consistent communication.
- **Send-MForgeMail:** Efficiently send mass mailings to large recipient lists with template support.
- **Template Orphan Removal:** Clean up unused or orphaned templates to keep your environment tidy.
- **Default Configuration:** Easily set up default mail settings for streamlined operations.
- **PSFramework Integration:** Leverage robust logging, configuration, and pipeline support.
- **Modern SMTP Support:** Uses Send-MailKitMessage for secure, standards-compliant mail delivery.

## Installation

```powershell
# Install the MailForge module from the PowerShell Gallery
Install-Module -Name MailForge -Scope CurrentUser
```

## Usage

**Important:**  
Never use MailForge to send sensitive information unless your mail infrastructure is secure. Always follow your organization's security policies.


### Example: Sending Password Expiry Notification

The module helps you send emails based on a template.

Suppose you want to notify users when their password is about to expire. The user information might look like this:

```json
{
    "GivenName": "Max",
    "Surname": "Mustermann",
    "SamAccountName": "mmustermann",
    "EmailAddress": "max.mustermann@example.org",
    "ExpireDate": "2025-10-30",
    "DaysToExpire": 20
}
```

A simple Markdown template could look like this:
```markdown
Hello þGivenNameþ þSurnameþ,

Your user account (**þSamAccountNameþ**) will expire on **þExpireDateþ**.

This means your password must be changed in **þDaysToExpireþ** days.

Please make sure to change your password in time to ensure uninterrupted access.

If you have any questions, please contact IT support.

Best regards  
Your IT Team
```

You can send the information directly with the following code:

```powershell
$templateData = @{
    GivenName      = "Max"
    Surname        = "Mustermann"
    SamAccountName = "mmustermann"
    EmailAddress   = "max.mustermann@example.org"
    ExpireDate     = "2025-10-30"
    DaysToExpire   = 20
}

Send-MForgeMail -WhatIf -TemplateFile .\expire.md -InputData $templateData -RecipientList $templateData.EmailAddress -Subject "Information about your user" -SMTPServer smtp.example.com -Port 25 -UseSecureConnectionIfAvailable $true -From "it-department@example.com"
```

With the WhatIf parameter, the function outputs the mail to the console instead of sending it:
```
RecipientList=max.mustermann@example.org
Subject=Information about your user
HtmlBody=<p>Hello Max Mustermann,</p>
<p>Your user account (<strong>mmustermann</strong>) will expire on <strong>2025-10-30</strong>.</p>
<p>This means your password must be changed in <strong>20</strong> days.</p>
<p>Please make sure to change your password in time to ensure uninterrupted access.</p>
<p>If you have any questions, please contact IT support.</p>
<p>Best regards<br />
Your IT Team</p>
```

You can simplify this further by registering default parameters once:

```powershell
Initialize-MForgeMailDefault -SMTPServer smtp.example.com -Port 25 -From "it-department@example.com"

# Shortened mail sending:
Send-MForgeMail -WhatIf -TemplateFile .\expire.md -InputData $templateData -RecipientList $templateData.EmailAddress -Subject "Information about your user"
```

If you prepare the template data accordingly, the function call becomes even shorter:

```powershell
$templateData = @{
    GivenName      = "Max"
    Surname        = "Mustermann"
    SamAccountName = "mmustermann"
    EmailAddress   = "max.mustermann@example.org"
    ExpireDate     = "2025-10-30"
    DaysToExpire   = 20
    Subject        = "Expiry info for user ID mmustermann"
}

Send-MForgeMail -WhatIf -TemplateFile .\expire.md -InputData $templateData
```

If the template is used frequently, you can register it and refer to it by a logical name. Input data can also be passed via pipeline:

```powershell
Register-MForgeTemplate -TemplateName "ExpireInfoMail" -TemplateFile .\expire.md
$templateData | Send-MForgeMail -WhatIf -TemplateName "ExpireInfoMail"
```

How do you send the mail to hundreds of users? First, you need the data:

```powershell
# Query all AD users with an email address and add calculated attributes
$pwdMaxAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
$users = Get-ADUser -Filter { EmailAddress -like "*" } -Properties EmailAddress, GivenName, Surname, PasswordLastSet, PasswordNeverExpires, SamAccountName |
    Select-PSFObject "GivenName", "Surname", "SamAccountName", "EmailAddress as RecipientList",
        @{ Name = 'ExpireDate'; Expression = { ($_.PasswordLastSet + $pwdMaxAge).ToString('yyyy-MM-dd') } },
        @{ Name = 'DaysToExpire'; Expression = { ($_.PasswordLastSet + $pwdMaxAge - (Get-Date)).Days } },
        @{ Name = 'Subject'; Expression = { "Password expiry info for user $($_.SamAccountName)" } }

# Only send mails to users whose password expires in 10 or 5 days
$filter = { $_.DaysToExpire -in @(5,10) }

$sendMailParam = @{
    TemplateName = "ExpireInfoMail"
    InputData    = $users
    Filter       = $filter
}

# Test output of mails to be sent, first 2 entries from user data
Send-MForgeMail @sendMailParam -Limit 2 -WhatIf
# Send first 2 mails to your own address for testing (RecipientList attribute in data is ignored)
Send-MForgeMail @sendMailParam -Limit 2 -RecipientList "devops@example.org"

# When everything is correct: send all mails
Send-MForgeMail @sendMailParam
```

### Example: Sending Emails Based on an Excel File
If the data required for sending is already available in an Excel file, you can use it directly as input:
```powershell
Send-MForgeMail -DataFile .\myData.xlsx -WorksheetName "userData" -Filter $Filter
```


## License

Distributed under the GNU GENERAL PUBLIC LICENSE version 3. See `LICENSE` for details.

## Contact

Project Link: [https://github.com/Callidus2000/MailForge](https://github.com/Callidus2000/MailForge)

## Acknowledgements

- [Friedrich Weinmann](https://github.com/FriedrichWeinmann) for [PSFramework](https://github.com/PowershellFrameworkCollective/psframework) and [PSModuleDevelopment](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment)
