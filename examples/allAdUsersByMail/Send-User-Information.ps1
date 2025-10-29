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


# # Group by mail address and create array with required structure
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

# Output result
$userArray | Send-MForgeMail -TemplateFile $PSScriptRoot\UserMailTemplate-WithLoop.md -Subject "User Information" -MailToAttr Mail -WhatIf -Confirm:$false
# Output result without sending mails:
# [Send-MForgeSingleMail] RecipientList=user1@example.com
# Subject=User Information
# HtmlBody=<h1 id="hello-user1-lastname1">Hello User1 Lastname1,</h1>
# <p>Below you will find a list of your accounts grouped by domain:</p>
# <hr />
# <h2 id="accounts-by-domain">Accounts by Domain</h2>
# <h3 id="domain-dummy.com">Domain: dummy.com</h3>
# <ul>
# <li>UPN: user1@dummy.com</li>
# <li>UPN: user2@dummy.com</li>
# </ul>
# <h3 id="domain-sample.org">Domain: sample.org</h3>
# <ul>
# <li>UPN: user3@sample.org</li>
# </ul>
# <p>Best regards,
# Your IT Team</p>

Prepare the User-List as template parameter:
$userArrayWithParams = $userArray | ForEach-Object {
    $userParam = $_ | ConvertTo-PSFHashtable
    $userParam.UserListMD= ($userParam.userList | Invoke-MForgeTemplate -TemplateString "- UPN: þUPNþ in þDomainþ" -TemplateType TXT -JoinResults)
    $userParam
}
$userArrayWithParams | Send-MForgeMail -TemplateFile $PSScriptRoot\UserMailTemplate-WithOutLoop.md -Subject "User Information" -MailToAttr Mail -WhatIf -Confirm:$false


# Results in:
# RecipientList=user2@example.com
# Subject=User Information
# HtmlBody=<h1 id="hello-user2-lastname2">Hello User2 Lastname2, </h1>
# <p>Below you will find a list of your accounts grouped by domain:</p>
# <hr />
# <h2 id="accounts-by-domain">Accounts by Domain</h2>
# <ul>
# <li>UPN: user2@example.com in example.com</li>
# <li>UPN: user2@sales.example.com in sales.example.com</li>
# </ul>
# <p>Best regards,
# Your IT Team</p>