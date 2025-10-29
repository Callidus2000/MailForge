function  Invoke-MForgeTemplate {
    [CmdletBinding()]
    param (
        # Mandatory parameters
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $TemplateParameters,

        # ParameterSet ByName
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [string]$TemplateName,

        # ParameterSet ByFile
        [Parameter(Mandatory = $true, ParameterSetName = 'ByFile')]
        [string]$TemplateFile,
        # ParameterSet ByString
        [Parameter(Mandatory = $true, ParameterSetName = 'ByString')]
        [string]$TemplateString,
        [Parameter(Mandatory = $true, ParameterSetName = 'ByString')]
        [ValidateSet("TXT", "HTML", "MD")]
        [string]$TemplateType = "TXT",
        [switch]$JoinResults

    )

    begin {
        if ($PSCmdlet.ParameterSetName -ne 'ByName') {
            $registerParam = $PSBoundParameters | convertto-psfhashtable -Include 'TemplateString', 'TemplateFile', 'TemplateType'
            Write-PSFMessage "Registering temporary template with parameters: $($registerParam|ConvertTo-Json -Compress)"
            # $templateName = Register-MForgeTemplate -TemplateFile $TemplateFile -Temporary
            $templateName = Register-MForgeTemplate @registerParam -Temporary
        }
        # if ($PSCmdlet.ParameterSetName -eq 'ByFile') {
        #     $templateName = Register-MForgeTemplate -TemplateFile $TemplateFile -Temporary
        # }
        $template = Get-PSMDTemplate $TemplateName
        if (-not $template) {
            Stop-PSFFunction -Level Warning -Message "Template $TemplateName not found"
            return
        }
        if ($JoinResults) {
            $allContent = @()
        }
    }

    process {
        foreach ($Parameters in $TemplateParameters) {
            Write-PSFMessage "Invoking template $TemplateName with parameters: $($Parameters|ConvertTo-Json -Compress)"
            $templateResults = Invoke-PSMDTemplate -TemplateName $TemplateName -Parameters ($Parameters | ConvertTo-PSFHashtable) -GenerateObjects
            # $content = $templateResults | Select-Object -First 1 -ExpandProperty Content
            $content = ($templateResults | Select-Object -First 1 -ExpandProperty Content).TrimEnd("`r", "`n")
            Write-PSFMessage "Template result content: #$content#"
            if ($JoinResults) {
                $allContent += $content
                continue
            }
            $content
        }
        # $templateResults = Invoke-PSMDTemplate -TemplateName $TemplateName -Parameters $TemplateParameters -GenerateObjects
        # $templateResults

        # switch -Regex (($template).Tags | Join-String -Separator ',') {
        #     'MD' {
        #         Write-PSFMessage "Konvertiere MarkDown nach HTML"
        #         $mdContent = $templateResults | Select-Object -First 1 -ExpandProperty Content
        #         $sendMailParams.HtmlBody = ($mdContent | ConvertFrom-Markdown).Html
        #     }
        #     'HTML' {
        #         Write-PSFMessage "Erzeuge HTML aus dem Template"
        #         $sendMailParams.HtmlBody = $templateResults | Select-Object -First 1 -ExpandProperty Content
        #     }
        # }
    }

    end {
        if ($JoinResults) {
            $allContent -join "`n"
        }
        if ($PSCmdlet.ParameterSetName -eq 'ByFile') {
            Write-PSFMessage "Removing temporary template $TemplateName."
            Remove-PSMDTemplate -TemplateName $TemplateName -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}