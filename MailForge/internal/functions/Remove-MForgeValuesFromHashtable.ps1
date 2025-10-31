function Remove-MForgeValuesFromHashtable {
    <#
    .SYNOPSIS
    Helper function to remove empty attributes from a provided HashTable.

    .DESCRIPTION
    Helper function to remove empty attributes from a provided HashTable.

    .PARAMETER InputObject
    The original Hashtable

    .PARAMETER NullHandler
    How should empty values be handled?
    -Keep: Keep the Attribute
    -RemoveAttribute: Remove the Attribute (default)
    -ClearContent: Clear the value

    .PARAMETER LongNullValue
    Which long value should be interpreted as "empty"

    .EXAMPLE
    $ht = @{
        Name = "John"
        Age = 42
        Email = ""
        Phone = $null
        Score = -1
    }
    $result = Remove-MForgeValuesFromHashtable -InputObject $ht -NullHandler "RemoveAttribute" -LongNullValue -1

    # Returns: @{ Name = "John"; Age = 42 }

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessforStateChangingFunctions', '')]
    param (
        [parameter(mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "default")]
        # [parameter(mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "clearEmpty")]
        # [parameter(mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "removeEmpty")]
        [HashTable]$InputObject,
        [ValidateSet("Keep", "RemoveAttribute", "ClearContent")]
        [parameter(mandatory = $false, ParameterSetName = "default")]
        $NullHandler = "RemoveAttribute",
        [parameter(mandatory = $false, ParameterSetName = "default")]
        [long]$LongNullValue = -1
        # ,
        # [parameter(mandatory = $false, ParameterSetName = "clearEmpty")]
        # [switch]$ClearEmptyArrays,
        # [parameter(mandatory = $false, ParameterSetName = "keepEmpty")]
        # [switch]$KeepEmptyAttribute
    )

    begin {
        if ($NullHandler -eq "RemoveAttribute") {
            $logLevel = "Debug"
        }
        else {
            $logLevel = "Verbose"
        }
    }

    process {
        if ($NullHandler -eq "Keep") {
            Write-PSFMessage "Returning inputObject unchanged" -Level $logLevel
            return $InputObject
        }
        $keyList = $InputObject.Keys | ForEach-Object { "$_" }
        foreach ($key in $keyList) {
            if ($null -eq $InputObject.$key) {
                $parameterType = 'null'
            }
            else {
                $parameterType = $InputObject.$key.gettype()
            }
            # Write-PSFMessage "Checking attribute $key of type $parameterType"
            switch -regex ($parameterType) {
                ".*\[\]" {
                    Write-PSFMessage "Checking null arrays" -Level $logLevel
                    if ($InputObject.$key.Count -gt 0 -and ([string]::IsNullOrEmpty($InputObject.$key[0]))) {
                        if ($NullHandler -eq "ClearContent") {
                            Write-PSFMessage "Replacing array attribute $key with empty array" -Level $logLevel
                            $InputObject.$key = @()
                        }
                        else {
                            Write-PSFMessage "Removing array attribute $key" -Level $logLevel
                            $InputObject.Remove($key)
                        }
                    }
                }
                "string|null" {
                    # Write-PSFMessage "Checking null string $key= $NullHandler/$([string]::IsNullOrEmpty($InputObject.$key))" -Level verbose
                    if (($NullHandler -eq "RemoveAttribute") -and (([string]::IsNullOrEmpty($InputObject.$key)) -or ([string]::IsNullOrEmpty($InputObject.$key)))) {
                        Write-PSFMessage "Removing string attribute $key" -Level $logLevel
                        $InputObject.Remove($key)
                    }
                }
                "long" {
                    if ($NullHandler -eq "RemoveAttribute" -and $InputObject.$key -eq $LongNullValue) {
                        Write-PSFMessage "Removing long attribute $key" -Level $logLevel
                        $InputObject.Remove($key)
                    }
                }
                Default { Write-PSFMessage "Unknown parameter type $parameterType" -Level $logLevel }
            }
        }
        return $InputObject
    }

    end {
    }
}