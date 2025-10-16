function Send-MForgeMassMail {
    <#
    .SYNOPSIS
    Sends mass emails based on an Excel file and a mail template.

    .DESCRIPTION
    Send-MForgeMassMail reads the specified Excel file and sends one email for each row.
    Recipients and subject can be provided either from a specified column in the Excel file or as a fixed parameter.
    Data rows can be filtered using a filter scriptblock, and the number of emails sent can be limited (e.g., for testing).
    All columns of the Excel row are available as placeholders in the template and can be used with the Unicode character þ (ALT+0254), e.g. þNameþ.
    The template can be specified by name (registered beforehand) or as a file. Additional settings like CC/BCC, subject, etc. are optional.

    .PARAMETER Credential
    Optional credential for SMTP authentication. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER SMTPServer
    SMTP server address. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER Port
    SMTP port. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER From
    Sender address. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER RecipientList
    List of recipient addresses. Default values can be set with Initialize-MForgeMailDefault. Overrides MailToColumn.

    .PARAMETER CCList
    List of CC addresses. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER BCCList
    List of BCC addresses. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER UseSecureConnectionIfAvailable
    Uses a secure connection if available. Default values can be set with Initialize-MForgeMailDefault.

    .PARAMETER Subject
    Subject of the email. Can be provided from a column in the Excel file (SubjectColumn) or as a fixed value.

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

    .PARAMETER MailToColumn
    Column name for the recipient address. Used if RecipientList is not set.

    .PARAMETER SubjectColumn
    Column name for the subject. Used if Subject is not set.

    .PARAMETER Limit
    Maximum number of emails to send (e.g., for testing).

    .PARAMETER MailToOverride
    Overrides the recipient address for all emails.

    .EXAMPLE
    Send-MForgeMassMail -TemplateName "Newsletter" -DataFile "data.xlsx" -WorksheetName "Recipients" -MailToColumn "Email"

    Sends emails based on the "Newsletter" template to all recipients in the "Email" column.

    .EXAMPLE
    Send-MForgeMassMail -TemplateFile "template.html" -DataFile "data.xlsx" -WorksheetName "Sheet1" -MailToColumn "Email" -SubjectColumn "Subject" -Limit 10 -Filter { $_.Status -eq 'Active' }

    Sends up to 10 emails to all active recipients, with subject and recipient taken from the respective columns in the Excel file. All columns are available as placeholders in the template.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
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

        # Mandatory parameters
        # ParameterSet ByName
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [string]$TemplateName,

        # ParameterSet ByFile
        [Parameter(Mandatory = $true, ParameterSetName = 'ByFile')]
        [string]$TemplateFile,

        [Parameter(Mandatory = $true)]
        [PsfFile]$DataFile,
        [scriptblock]$Filter = { $true },
        [Parameter(Mandatory = $true)]
        [string]$WorksheetName,
        [string]$MailToColumn,
        [string]$SubjectColumn,
        [int]$Limit = 0,
        [string]$MailToOverride
    )
    $singleMailParams = $PSBoundParameters | ConvertTo-PSFHashtable -ReferenceCommand "Send-MForgeMail" -Exclude TemplateFile
    Write-PSFMessage "Single Mail Params: $($singleMailParams|ConvertTo-Json -Compress)"
    if ($PSCmdlet.ParameterSetName -eq 'ByFile') {
        $templateName = Register-MForgeTemplate -TemplateFile $TemplateFile -Temporary
        $singleMailParams.TemplateName = $templateName
    }
    $rawData = Import-Excel -Path $DataFile -WorksheetName $WorksheetName
    $SelectParam = @{}
    if ($Limit -gt 0) {
        $SelectParam.First = $Limit
    }
    $TemplateData = $rawData | Select-Object @SelectParam | where-object $Filter
    Write-PSFMessage "File $DataFile imported, $($TemplateData.Count) entries after filtering original $($rawData.Count)"
    $uniqueRecipients = ($TemplateData | Select-Object -ExpandProperty $MailToColumn -ErrorAction SilentlyContinue | Measure-Object).count
    if ($RecipientList) {
        Write-PSFMessage -Level Host -Message "RecipientList parameter is set, ignoring MailToColumn and sending $($TemplateData.Count) mails to $($RecipientList.Count) recipients"
        $ConfirmMessage = "Sending $($TemplateData.Count) mails to $($RecipientList.Count) recipients"
        $MailToOverride = $RecipientList
    }
    else {
        $ConfirmMessage = "Sending $($TemplateData.Count) mails to $uniqueRecipients unique recipients from column $MailToColumn"
    }
    Invoke-PSFProtectedCommand -Action $ConfirmMessage -ScriptBlock {
        if ([string]::IsNullOrEmpty($TemplateData)) {
            Stop-PSFFunction -Level Warning -Message "No data found in Excel" -EnableException $true
        }
        if ($SubjectColumn -and -not $TemplateData[0].$SubjectColumn) {
            Stop-PSFFunction -Level Warning -Message "SubjectColumn '$SubjectColumn' not found in data, please check your input." -EnableException $true
        }
        if ($MailToColumn -and -not $TemplateData[0].$MailToColumn) {
            Stop-PSFFunction -Level Warning -Message "MailToColumn '$MailToColumn' not found in data, please check your input." -EnableException $true
        }
        if ($MailToOverride) {
            $singleMailParams.RecipientList = $MailToOverride
        }
        $TemplateData = $TemplateData | ConvertTo-PSFHashtable
        foreach ($entry in $TemplateData) {
            if (-not $MailToOverride) {
                $singleMailParams.RecipientList = $entry.$MailToColumn
            }
            if ($SubjectColumn -and $entry.PSObject.Properties.Name -contains $SubjectColumn) {
                $singleMailParams.Subject = $entry.$SubjectColumn
            }
            Write-PSFMessage "Sending mail to $($singleMailParams.RecipientList) with subject '$($singleMailParams.Subject)'"
            Write-PSFMessage "Mail Parameters: $($singleMailParams | ConvertTo-Json -Compress)"
            Send-MForgeMail @singleMailParams -templateParameters $entry
        }
    }
    if ($PSCmdlet.ParameterSetName -eq 'ByFile') {
        Write-PSFMessage "Removing temporary template $templateName"
        Remove-PSMDTemplate -TemplateName $TemplateName -Confirm:$false -ErrorAction SilentlyContinue
    }
}