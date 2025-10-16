function Send-MForgeMassMail {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # Optional parameters from Initialize-MForgeMailDefault
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
    Save-ContextCache -Name "Send-MForgeMassMail" -CurrentVariables (get-variable -Scope Local)
}