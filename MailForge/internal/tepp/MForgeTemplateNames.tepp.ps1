Register-PSFTeppScriptblock -Name "MForgeTemplateNames" -ScriptBlock {
    Get-PSMDTemplate -ErrorAction SilentlyContinue | Where-Object { $_.Tags -contains 'MailForge' } | Select-Object -ExpandProperty name
}