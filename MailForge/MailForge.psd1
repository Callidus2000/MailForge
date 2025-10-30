@{
	# Script module or binary module file associated with this manifest
	RootModule = 'MailForge.psm1'

	# Version number of this module.
	ModuleVersion = '2.1.1'

	# ID used to uniquely identify this module
	GUID = '503678cb-acac-464d-bd61-9e7ac9c29834'

	# Author of this module
	Author = 'Sascha Spiekermann'

	# Company or vendor of this module
	CompanyName = 'MyCompany'

	# Copyright statement for this module
	Copyright = 'Copyright (c) 2025 Sascha Spiekermann'

	# Description of the functionality provided by this module
	Description = 'MailForge is a PowerShell module for automated email delivery, template management, and mass mailing. It supports dynamic templates with placeholders, Excel-based recipient lists, and integrates with modern SMTP systems for secure, scalable communication.'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.0'

	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules = @(
		@{ ModuleName='ImportExcel'; ModuleVersion='7.8.10' }
		@{ ModuleName='PSFramework'; ModuleVersion='1.13.414' }
		@{ ModuleName = 'PSModuleDevelopment'; ModuleVersion = '2.2.13.176' }
		@{ ModuleName = 'Send-MailKitMessage'; ModuleVersion = '3.2.0' }
	)

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\MailForge.dll')

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\MailForge.Types.ps1xml')

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @('xml\MailForge.Format.ps1xml')

	# Functions to export from this module
	FunctionsToExport = @(
		'Get-MForgeMailDefault'
		'Initialize-MForgeMailDefault'
		'Invoke-MForgeTemplate'
		'Register-MForgeTemplate'
		'Remove-MForgeTemplate'
		'Send-MForgeMail'
	)

	# Cmdlets to export from this module
	CmdletsToExport = ''

	# Variables to export from this module
	VariablesToExport = ''

	# Aliases to export from this module
	AliasesToExport = ''

	# List of all modules packaged with this module
	ModuleList = @()

	# List of all files packaged with this module
	FileList = @()

	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		#Support for PowerShellGet galleries.
		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @('mail','email','template','automation','powershell','smtp','massmail','psframework')

			# A URL to the license for this module.
			LicenseUri = 'https://github.com/Callidus2000/MailForge/blob/master/LICENSE'

			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/Callidus2000/MailForge'

			# A URL to an icon representing this module.
			# IconUri = ''

			# ReleaseNotes of this module
						ReleaseNotes = @'
v2.0.1 (2025-10-29)
 - Help comments for Invoke-MForgeTemplate improved and translated to English.
 - Examples in Invoke-MForgeTemplate help block now include explanations and blank lines.
 - Mandatory parameter "TemplateType" no longer has a default value in Invoke-MForgeTemplate.
 - TemplateFile parameters now strictly check if the file exists before execution.
 - Internal preparations for further PSScriptAnalyzer compliance and refactoring.

v2.0.0 (2025-10-29)
 - Breaking Change: Renamed Send-MForgeMail to Send-MForgeSingleMail, moved it to internal functions.
 - Breaking Change: Renamed Send-MForgeMassMail to Send-MForgeMail.
 - Subject parameter now supports template strings with placeholders (þ...þ), resolved per mail.
 - Improved error handling for missing Subject or Recipient (Test-MForgeParameter).
 - Enhanced pipeline and parameter handling for mass mail scenarios.
 - Documentation and comments translated to English.
 - Various bugfixes and refactoring for consistency.

v1.1.0 (2025-10-24)
 - Breaking Change: The parameters `MailToColumn` and `SubjectColumn` have been renamed to `MailToAttr` and `SubjectAttr` and now have default values 'MailTo' and 'Subject'.
	 If the parameters `RecipientList` or `Subject` are provided, they override the values from the data.
	 Note: This breaking change does not lead to v2, as the module is still very new.
 - Enhancement: Mass mail data can now also be provided directly via parameter or pipeline, not only via Excel.

v1.0.0 (2025-10-16)
 - Initial Release
'@

		} # End of PSData hashtable

	} # End of PrivateData hashtable
}