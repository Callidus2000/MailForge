<!-- PROJECT SHIELDS -->
[![Contributors](https://img.shields.io/github/contributors/Callidus2000/MailForge.svg?style=for-the-badge)](https://github.com/Callidus2000/MailForge/graphs/contributors)
[![Forks](https://img.shields.io/github/forks/Callidus2000/MailForge.svg?style=for-the-badge)](https://github.com/Callidus2000/MailForge/network/members)
[![Stargazers](https://img.shields.io/github/stars/Callidus2000/MailForge.svg?style=for-the-badge)](https://github.com/Callidus2000/MailForge/stargazers)
[![Issues](https://img.shields.io/github/issues/Callidus2000/MailForge.svg?style=for-the-badge)](https://github.com/Callidus2000/MailForge/issues)
[![GPLv3 License](https://img.shields.io/github/license/Callidus2000/MailForge.svg?style=for-the-badge)](https://github.com/Callidus2000/MailForge/blob/master/LICENSE)

# MailForge PowerShell Module

**MailForge** is a PowerShell module for automating, templating, and sending emails in enterprise environments. It provides advanced features for mass mailing, template management, and integration with modern mail systems, making it ideal for IT automation, notifications, and bulk communications.

## Features

- **Send-MForgeMail:** Send individual or bulk emails using registered or file-based templates, with dynamic parameters.
- **Register-MForgeTemplate:** Create and manage reusable mail templates for consistent communication.
- **Send-MForgeMassMail:** Efficiently send mass mailings to large recipient lists with template support.
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



### Register a Template and Send an Email

```powershell
# Register a template from a file (HTML or Markdown)
Register-MForgeTemplate -TemplateFile ".\templates\welcome.html" -TemplateName "Welcome"

# Send an email using the registered template
Send-MForgeMail -TemplateName "Welcome" -RecipientList "user@company.com" -TemplateParameters @{ Name = "Max Mustermann" }
```


### Use a Template for Mass Mailing

```powershell
# Register a template from a Markdown file
Register-MForgeTemplate -TemplateFile ".\templates\info.md" -TemplateName "InfoMail"

# Send mass mail using the template and Excel data
Send-MForgeMassMail -TemplateName "InfoMail" -DataFile ".\data\recipients.xlsx" -WorksheetName "Sheet1" -MailToColumn "Email"
```

This example registers a mail template from a Markdown file and then sends a mass mailing using that template. The recipient addresses are read from the "Email" column of the specified Excel worksheet. For each row in the Excel file, an email is generated using the template and the row's data as template parameters. You can use any column from the Excel file as a placeholder in the template (e.g., `þNameþ`).

```powershell
Send-MForgeMassMail -TemplateFile "template.html" -DataFile "data.xlsx" -WorksheetName "Sheet1" -MailToColumn "Email" -SubjectColumn "BetSubjectreff" -Limit 10 -Filter { $_.Status -eq 'Active' }
```

Sends up to 10 emails to all active recipients, with subject and recipient taken from the respective columns in the Excel file. All columns are available as placeholders in the template.

**Notes:**
- Template files must be either `.html` or `.md`. The file extension is used for recognition.
- Placeholders in templates are enclosed with the Unicode character þ (ALT+0254), e.g. `þNameþ`. This allows dynamic replacement of values when sending mails.
- For template best practices and advanced scenarios, see [PSModuleDevelopment Templates Quickstart](https://psframework.org/docs/quickstart/PSModuleDevelopment/templates-new).
- The parameter names for sending mail are: `TemplateName`, `TemplateFile`, `TemplateParameters`, `RecipientList`, and optionally `Subject`, `CCList`, `BCCList`, etc. See function help for details.

### Remove Orphaned Templates

```powershell
Remove-MForgeTemplateOrphan
```

## Project Structure

- Exported functions: `functions/`
- Internal/private functions: `internal/functions/`
- Templates, config, and help: `en-us/`, `xml/`, `internal/configurations/`
- Tests: `tests/`

## Contributing

Contributions are welcome! Please fork the repo, submit pull requests, or open issues for feature requests and bug reports.

## License

Distributed under the GNU GENERAL PUBLIC LICENSE version 3. See `LICENSE` for details.

## Contact

Project Link: [https://github.com/Callidus2000/MailForge](https://github.com/Callidus2000/MailForge)


## Acknowledgements

- [Friedrich Weinmann](https://github.com/FriedrichWeinmann) for [PSFramework](https://github.com/PowershellFrameworkCollective/psframework) and
- [PSModuleDevelopment](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment)
### Example: Mass Mailing from Excel

`Send-MForgeMassMail` allows you to send mass emails based on an Excel file and a template. For each row in the Excel file, an email is generated. Recipients and subject can be provided either from a column in the Excel file or as a fixed parameter. You can filter the data rows using a filter scriptblock and limit the number of emails sent (e.g., for testing).

All columns of the Excel row are available as placeholders in the template and can be used with the Unicode character þ (ALT+0254), e.g. `þNameþ`. The template can be specified by name (registered beforehand) or as a file. Additional settings like CC/BCC, subject, etc. are optional.

**Example:**

```powershell
Send-MForgeMassMail -TemplateFile "template.html" -DataFile "data.xlsx" -WorksheetName "Sheet1" -MailToColumn "Email" -SubjectColumn "Subject" -Limit 10 -Filter { $_.Status -eq 'Active' }
```

Sends up to 10 emails to all active recipients, with subject and recipient taken from the respective columns in the Excel file. All columns are available as placeholders in the template.

### Example: Send AD User Information

This example demonstrates how to send personalized account information to all users in an Active Directory forest. For each user, all their accounts (UPNs) are grouped by domain and sent via email using a Markdown template. The example shows both a template with a loop and a template with a pre-rendered user list.

```powershell
# Get all domains in the forest, real Data
# $forest = Get-ADForest
# $domains = $forest.Domains

# $allUsers = foreach ($domain in $domains) {
#     Get-ADUser -Server $domain -Filter "mail -like '*'" -Properties givenName,surname,mail,userPrincipalName |
#         Select-Object @{Name='Domain';Expression={$domain}},
#                       @{Name='FirstName';Expression={$_.givenName}},
#                       @{Name='LastName';Expression={$_.surname}},
#                       @{Name='Mail';Expression={$_.mail}},
#                       @{Name='UPN';Expression={$_.userPrincipalName}}
# }

# Group by mail address and create array with required structure
# $userArray = $allUsers | Group-Object -Property Mail | ForEach-Object {
#     $firstUser = $_.Group | Select-Object -First 1
#     [PSCustomObject]@{
#         Mail      = $_.Name
#         FirstName = $firstUser.FirstName
#         LastName  = $firstUser.LastName
#         UserList  = $_.Group
#     }
# }

# Provide sample data for testing
$userArray=@"
[{"Mail":"user1@example.com","FirstName":"User1","LastName":"Lastname1","UserList":[{"Domain":"example.com","FirstName":"User1","LastName":"Lastname1","Mail":"user1@example.com","UPN":"user1@example.com"},{"Domain":"sales.example.com","FirstName":"User1","LastName":"Lastname1","Mail":"user1@example.com","UPN":"user1@sales.example.com"}]},{"Mail":"user2@example.com","FirstName":"User2","LastName":"Lastname2","UserList":[{"Domain":"example.com","FirstName":"User2","LastName":"Lastname2","Mail":"user2@example.com","UPN":"user2@example.com"},{"Domain":"sales.example.com","FirstName":"User2","LastName":"Lastname2","Mail":"user2@example.com","UPN":"user2@sales.example.com"}]},{"Mail":"user3@example.com","FirstName":"User3","LastName":"Lastname3","UserList":[{"Domain":"sales.example.com","FirstName":"User3","LastName":"Lastname3","Mail":"user3@example.com","UPN":"user3@sales.example.com"}]}]
"@ |ConvertFrom-Json

# Send mail using template with loop
$userArray | Send-MForgeMassMail -TemplateFile .\UserMailTemplate-WithLoop.md -Subject "User Information" -MailToAttr Mail -WhatIf -Confirm:$false

# Prepare the User-List as template parameter for template without loop
$userArrayWithParams = $userArray | ForEach-Object {
    $userParam = $_ | ConvertTo-PSFHashtable
    $userParam.UserListMD= ($userParam.userList | Invoke-MForgeTemplate -TemplateString "- UPN: þUPNþ in þDomainþ" -TemplateType TXT -JoinResults)
    $userParam
}
$userArrayWithParams | Send-MForgeMassMail -TemplateFile .\UserMailTemplate-WithOutLoop.md -Subject "User Information" -MailToAttr Mail -WhatIf -Confirm:$false
```

Templates used:

**UserMailTemplate-WithLoop.md**
```markdown
# Hello þFirstNameþ þLastNameþ,

Below you will find a list of your accounts grouped by domain:

---

## Accounts by Domain
þ{
    foreach($user in $Parameters.UserList){ 
    "### Domain: $($User.Domain)","- UPN: $($User.UPN)","`n"|Join-String -Separator "`n"
    }
}þ

Best regards,
Your IT Team
```

**UserMailTemplate-WithOutLoop.md**
```markdown
# Hello þFirstNameþ þLastNameþ,

Below you will find a list of your accounts grouped by domain:

---

## Accounts by Domain
þUserListMDþ

Best regards,
Your IT Team
```
