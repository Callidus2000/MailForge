# Changelog
## 2.0.0 (2025-10-29)
 - Breaking Change: Renamed Send-MForgeMail to Send-MForgeSingleMail, moved it to internal functions.
 - Breaking Change: Renamed Send-MForgeMassMail to Send-MForgeMail.
 - Subject parameter now supports template strings with placeholders (þ...þ), resolved per mail.
 - Improved error handling for missing Subject or Recipient (Test-MForgeParameter).
 - Enhanced pipeline and parameter handling for mass mail scenarios.
 - Documentation and comments translated to English.
 - Various bugfixes and refactoring for consistency.
## 1.1.0 (2025-10-24)
 - Breaking Change: The parameters `MailToColumn` and `SubjectColumn` have been renamed to `MailToAttr` and `SubjectAttr` and now have default values 'MailTo' and 'Subject'.
	 If the parameters `RecipientList` or `Subject` are provided, they override the values from the data.
	 Note: This breaking change does not lead to v2, as the module is still very new.
 - Enhancement: Mass mail data can now also be provided directly via parameter or pipeline, not only via Excel.

## 1.0.0 (2025-10-16)
 - Initial Release