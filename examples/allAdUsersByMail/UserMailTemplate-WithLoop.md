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
