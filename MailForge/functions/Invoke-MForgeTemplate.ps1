function  Invoke-MForgeTemplate {
    <#
    .SYNOPSIS
    Executes a MailForge template with the specified parameters.

    .DESCRIPTION
    This function allows you to execute a MailForge template by name, file, or string.
    The parameters are passed to the template and the result is returned. Supports
    different parameter sets for flexible usage.

    .PARAMETER TemplateParameters
    Hashtable with parameters to pass to the template.

    .PARAMETER TemplateName
    Name of the template to execute (ParameterSet 'ByName').

    .PARAMETER TemplateFile
    Path to the template file (ParameterSet 'ByFile').

    .PARAMETER TemplateString
    Template content as string (ParameterSet 'ByString').

    .EXAMPLE
    Invoke-MForgeTemplate -TemplateName "WelcomeMail" -TemplateParameters $params

    # Executes the template named "WelcomeMail" with the given parameters.

    .EXAMPLE
    Invoke-MForgeTemplate -TemplateFile "template.ps1" -TemplateParameters $params

    # Executes the template from the file "template.ps1" with the given parameters.

    .EXAMPLE
    Invoke-MForgeTemplate -TemplateString $content -TemplateParameters $params

    # Executes the template from the string variable $content with the given parameters.

    #>
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
        [string]$TemplateString
    )

    begin {
        if ($PSCmdlet.ParameterSetName -ne 'ByName') {
            $registerParam = $PSBoundParameters | convertto-psfhashtable -Include 'TemplateString', 'TemplateFile'
            $registerParam.TemplateType = 'TXT'
            Write-PSFMessage "Registering temporary template with parameters: $($registerParam|ConvertTo-Json -Compress)"
            # $templateName = Register-MForgeTemplate -TemplateFile $TemplateFile -Temporary
            $templateName = Register-MForgeTemplate @registerParam -Temporary
        }
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

    }

    end {
        if ($JoinResults) {
            $allContent -join "`n"
        }
        if ($PSCmdlet.ParameterSetName -ne 'ByName') {
            Write-PSFMessage "Removing temporary template $TemplateName."
            Remove-PSMDTemplate -TemplateName $TemplateName -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}