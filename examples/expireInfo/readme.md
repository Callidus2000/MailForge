The module helps you send emails based on a template.

Suppose you want to send users an email with information about when their user password will expire. The information for a user might look like this:

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

To keep the template simple, create the following Markdown file:
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

This can be greatly simplified. The standard parameters can be registered once so that they are automatically used:
```powershell
Initialize-MForgeMailDefault -SMTPServer smtp.example.com -Port 25 -From "it-department@example.com"

# Shortened mail sending:
Send-MForgeMail -WhatIf -TemplateFile .\expire.md -InputData $templateData -RecipientList $templateData.EmailAddress -Subject "Information about your user"
```

If you further prepare the template data, the function call becomes even shorter:
```powershell
$templateData = @{
    GivenName      = "Max"
    Surname        = "Mustermann"
    SamAccountName = "mmustermann"
    MailTo         = "max.mustermann@example.org"
    ExpireDate     = "2025-10-30"
    DaysToExpire   = 20
    Subject        = "Expiry info for user ID mmustermann"
}

Send-MForgeMail -WhatIf -TemplateFile .\expire.md -InputData $templateData
```

If the template is used more frequently, you can register it and refer to it by a logical name. The input data can also be passed via pipeline:

```powershell
Register-MForgeTemplate -TemplateName "ExpireInfoMail" -TemplateFile .\expire.md
$templateData | Send-MForgeMail -WhatIf -TemplateName "ExpireInfoMail"
```

How do you send the mail to hundreds of users? First, you need the data:

```powershell
# Query all AD users with an email address and add calculated attributes
$pwdMaxAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
$users = Get-ADUser -Filter { EmailAddress -like "*" } -Properties EmailAddress, GivenName, Surname, PasswordLastSet, PasswordNeverExpires, SamAccountName |
    Select-PSFObject "GivenName", "Surname", "SamAccountName", "EmailAddress as MailTo",
        @{ Name = 'ExpireDate'; Expression = { ($_.PasswordLastSet + $pwdMaxAge).ToString('yyyy-MM-dd') } },
        @{ Name = 'DaysToExpire'; Expression = { ($_.PasswordLastSet + $pwdMaxAge - (Get-Date)).Days } },
        @{ Name = 'Subject'; Expression = { "Password expiry info for user $($_.SamAccountName)" } }

# Only send mails to users whose password expires in 10 or 5 days
# Create filter:
$filter = { $_.DaysToExpire -in @(5,10) }

$sendMailParam = @{
    TemplateName = "ExpireInfoMail"
    InputData    = $users
    Filter       = $filter
}

# Test output of mails to be sent, first 2 entries from user data
Send-MForgeMail @sendMailParam -Limit 2 -WhatIf
# Send first 2 mails to your own address for testing (MailTo attribute in data is ignored)
Send-MForgeMail @sendMailParam -Limit 2 -RecipientList "devops@example.org"

# When everything is correct: send all mails
Send-MForgeMail @sendMailParam
```