# Changelog
## 2.1.1 (2025-10-30)
 - Enhancement: Improved error handling for missing or invalid ParameterMapping.
 - Enhancement: Added support for dynamic attribute mapping in Send-MForgeMail.
 - Documentation: Updated help blocks for Send-MForgeMail to clarify InputData and mapping usage.
 - Internal: Refactored pipeline handling for InputData and empty values.
 - Internal: Minor bugfixes and code cleanup.

## 2.1.0 (2025-10-30)
 - Enhancement: Send-MForgeMail now supports flexible mapping of mail parameters via ParameterMapping.
 - Enhancement: Pipeline input for InputData is now fully supported.
 - Documentation: Help comments and examples updated for new mapping logic.
 - Internal: Improved Select-PSFObject usage for dynamic parameter selection.

## 2.0.2 (2025-10-29)
 - Enhancement: Added generic ParameterMapping hashtable for flexible attribute mapping.
 - Enhancement: Input data can now be provided via InputData parameter or pipeline, not only Excel.
 - Documentation: Help block and comments updated to clarify InputData and ParameterMapping usage.
 - Documentation: WhatIf notes retained in help block.
 - Internal: Default mapping for From, RecipientList, CCList, BCCList, Subject now configurable via ParameterMapping.
 - Internal: German comments and messages translated to English.
 - Internal: Improved example blocks in help comments.
## 2.0.1 (2025-10-29)
 - Documentation: Help comments for Invoke-MForgeTemplate improved and translated to English.
 - Examples in Invoke-MForgeTemplate help block now include explanations and blank lines.
 - Fixed: Mandatory parameter 'TemplateType' no longer has a default value in Invoke-MForgeTemplate.
 - Internal: Preparations for further PSScriptAnalyzer compliance and refactoring.
 - Enhancement: TemplateFile parameters now strictly check if the file exists before execution.
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