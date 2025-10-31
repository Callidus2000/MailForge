function Send-MForgeMail {
    <#
    .SYNOPSIS
    Sends mass emails based on input data (pipeline or Excel file) and a mail template.

    .DESCRIPTION
    Send-MForgeMail processes input data provided either via the InputData parameter (including
    pipeline input) or from an Excel file. For each data row, an email is sent using a template.
    Recipients and subject can be provided from a specified column in the input data or as a fixed
    parameter. Data rows can be filtered using a filter scriptblock, and the number of emails sent can
    be limited (e.g., for testing). All columns of the input data row are available as placeholders in
    the template and can be used with the Unicode character þ (ALT+0254), e.g. þNameþ. The template can
    be specified by name (registered beforehand) or as a file. Additional settings like CC/BCC, subject,
    etc. are optional.

    .PARAMETER Credential
    Optional credential for SMTP authentication. Default values can be set with
    Initialize-MForgeMailDefault.

    .PARAMETER SMTPServer
    SMTP server address. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER Port
    SMTP port. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER From
    Sender address. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER RecipientList
    List of recipient addresses. Default values can be set with Initialize-MForgeMailDefault.
    Overrides attribute mapping.

    .PARAMETER CCList
    List of CC addresses. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER BCCList
    List of BCC addresses. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER UseSecureConnectionIfAvailable
    Uses a secure connection if available. Default values can be set with
    Initialize-MForgeMailDefault.

    .PARAMETER Subject
    Subject of the email. Can be provided from a column in the Excel file or as a fixed value.

    .PARAMETER TemplateName
    Name of the template to use. Must be registered beforehand with Register-MForgeTemplate.

    .PARAMETER TemplateFile
    Path to the template file (.html or .md).

    .PARAMETER DataFile
    Excel file containing recipient data.

    .PARAMETER Filter
    Scriptblock for filtering data rows. Default: all rows.

    .PARAMETER WorksheetName
    Name of the Excel worksheet.

    .PARAMETER ParameterMapping
    Hashtable mapping parameter names to attribute names, e.g. @{Subject='Subject';RecipientList='MailTo'}.

    .PARAMETER Limit
    Maximum number of emails to send (e.g., for testing).

    .EXAMPLE
    Send-MForgeMail -TemplateName "Newsletter" -DataFile "data.xlsx" -WorksheetName "Recipients"
        -ParameterMapping @{RecipientList='Email'}

    Sends emails based on the "Newsletter" template to all recipients in the "Email" column.

    .EXAMPLE
    Send-MForgeMail -TemplateFile "template.html" -DataFile "data.xlsx" -WorksheetName "Sheet1"
        -ParameterMapping @{RecipientList='Email';Subject='Subject'} -Limit 10
        -Filter { $_.Status -eq 'Active' }

    Sends up to 10 emails to all active recipients, with subject and recipient taken from the respective
    columns in the Excel file. All columns are available as placeholders in the template.

    .NOTES
    If -WhatIf is specified, the mail information (recipient, subject, content) will be displayed on the
    console, but no mails will be sent.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        # Optional parameters from Initialize-MForgeMail
        [pscredential]$Credential,
        [string]$SMTPServer,
        [int]$Port,
        $From, # MailboxAddress
        $RecipientList, # InternetAddressList
        $CCList, # InternetAddressList
        $BCCList, # InternetAddressList
        [boolean]$UseSecureConnectionIfAvailable,
        [string]$Subject,

        # Template selection
        [string]$TemplateName,
        [PSFFile]$TemplateFile,

        # Data input from Excel
        [Parameter(ParameterSetName = 'dataFromExcel', Mandatory = $true)]
        [PsfFile]$DataFile,
        [Parameter(ParameterSetName = 'dataFromExcel', Mandatory = $true)]
        [string]$WorksheetName,

        # Data input from pipeline
        [Parameter(ParameterSetName = 'dataFromPipeline', ValueFromPipeline = $true)]
        [object[]]$InputData,

        # Common parameters
        [scriptblock]$Filter = { $true },
        [hashtable]$ParameterMapping,
        [int]$Limit = 0
    )
    begin {
        $singleMailParams = $PSBoundParameters | ConvertTo-PSFHashtable -ReferenceCommand "Send-MForgeSingleMail" -Exclude TemplateFile | Remove-MForgeValuesFromHashtable
        Write-PSFMessage "Single Mail Params: $($singleMailParams|ConvertTo-Json -Compress)"
        if ($PSBoundParameters.ContainsKey('TemplateFile')) {
            $templateName = Register-MForgeTemplate -TemplateFile $TemplateFile -Temporary
            $singleMailParams.TemplateName = $templateName
        }
        if (-not $TemplateName){
            Stop-PSFFunction -Level Warning -Message "TemplateName is required either via -TemplateName or -TemplateFile" -EnableException $true
        }
        $rawData = @()
        if ($PSBoundParameters.ContainsKey('DataFile') -and $PSBoundParameters.ContainsKey('WorksheetName')) {
            $rawData = Import-Excel -Path $DataFile -WorksheetName $WorksheetName
        }
        # By default, map standard parameter names to attribute names
        # This mapping is used to provide the named parameters from the data attributes
        # ParameterMapping: Key=Value means ParameterName=AttributeName in the data.
        # Data can be provided either via InputData (including pipeline) or from an Excel file.
        $ParameterMappingTable = @{
            From          = 'From'
            RecipientList = 'RecipientList'
            CCList        = 'CCList'
            BCCList       = 'BCCList'
            Subject       = 'Subject'
        }
        # The user-provided mapping overrides the default mapping
        if ($ParameterMapping) {
            foreach ($key in $ParameterMapping.Keys) {
                $ParameterMappingTable.$key = $ParameterMapping.$key
            }
        }
        # The following Property array is later used by Select-PSFObject to select and rename the attributes of the provided $InputData
        # and provide them as parameters to Send-MForgeSingleMail
        $possibleParameterKeys = $singleMailParams.Keys + $ParameterMappingTable.keys | Select-Object -Unique
        # $psfSelectParam = $ParameterMappingTable.Keys | ForEach-Object {
        $psfSelectParam = $possibleParameterKeys | ForEach-Object {
            if ($singleMailParams.ContainsKey($_)) {
                "`$$_ as $_"
            }
            else {
                "$($ParameterMappingTable.$_) as $_"
            }
        }
        $psfSelectParam += '$_ as templateParameters'
        Write-PSFMessage "Parameter Mapping resulting Select-PSFObject parameters: $($psfSelectParam | Join-String -Separator ', ')"
        Write-PSFMessage "`$ConfirmPreference=$($ConfirmPreference)"
        if ($WhatIfPreference) {
            # WhatIf was specified, do nothing here
        }
        $rawDataSelectParam = @{
            Property = $psfSelectParam
        }
        if ($Limit -gt 0) {
            $rawDataSelectParam.First = $Limit
        }
    }
    process {
        $rawData += $InputData
    }
    end {
        $TemplateData = [array]($rawData | Where-Object $Filter | Select-PSFObject @rawDataSelectParam | ConvertTo-PSFHashtable | Remove-MForgeValuesFromHashtable)
        $uniqueRecipients = ($TemplateData | Select-Object -ExpandProperty RecipientList -ErrorAction SilentlyContinue -Unique | Measure-Object).count
        $ConfirmMessage = "Sending $($TemplateData.Count) mails to $($uniqueRecipients.Count) recipients"

        Write-PSFMessage "Data imported, $(($templateData|Measure-Object).Count) entries after filtering original $($rawData.Count)"
        Save-ContextCache -Name "murks" -CurrentVariables (Get-Variable -Scope local)
        if ([string]::IsNullOrEmpty($TemplateData)) {
            Stop-PSFFunction -Level Warning -Message "No data found" -EnableException $true
        }
        # TODO: Eine Überprüfung auf notwendige Parameter einbauen

        # Check if Subject is provided from parameter and contains the Placeholder delimiter
        if ($PSBoundParameters.ContainsKey('Subject') -and $Subject -like "*þ*") {
            $subjectTemplateName = Register-MForgeTemplate -TemplateString $Subject -TemplateType 'TXT' -Temporary
        }
        $TemplateData | ForEach-Object {
            if ($_.Subject -match 'þ') {
                Write-PSFMessage "Generating subject from template $subjectTemplateName"
                $_.Subject = Invoke-MForgeTemplate -TemplateName $subjectTemplateName -TemplateParameters $_.templateParameters
            }
        }
        Invoke-PSFProtectedCommand -Action $ConfirmMessage -ScriptBlock {
            foreach ($mailParam in $TemplateData) {
                Write-PSFMessage "Sending mail to $($mailParam.RecipientList) with subject '$($mailParam.Subject)'" -FunctionName Send-MForgeMail
                Write-PSFMessage "Mail Parameters: $($mailParam | ConvertTo-Json -Compress)" -FunctionName Send-MForgeMail
                Send-MForgeSingleMail @mailParam -WhatIf:$WhatIfPreference -verbose
            }
        } -WhatIf:$false -Confirm:$ConfirmPreference
        if ($PSBoundParameters.ContainsKey('TemplateFile')) {
            Write-PSFMessage "Removing temporary template $templateName"
            Remove-PSMDTemplate -TemplateName $TemplateName -Confirm:$false -ErrorAction SilentlyContinue
        }
        if ($subjectTemplateName) {
            Write-PSFMessage "Removing temporary subject template $subjectTemplateName"
            Remove-PSMDTemplate -TemplateName $subjectTemplateName -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}