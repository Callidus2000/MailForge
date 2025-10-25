# Changelog
## 1.1.0 (2025-10-24)
 - Breaking Change: The parameters `MailToColumn` and `SubjectColumn` have been renamed to `MailToAttr` and `SubjectAttr` and now have default values 'MailTo' and 'Subject'.
	 If the parameters `RecipientList` or `Subject` are provided, they override the values from the data.
	 Note: This breaking change does not lead to v2, as the module is still very new.
 - Enhancement: Mass mail data can now also be provided directly via parameter or pipeline, not only via Excel.

## 1.0.0 (2025-10-16)
 - Initial Release