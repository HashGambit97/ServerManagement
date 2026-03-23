function NewDracCimSession
{
    <#
    .SYNOPSIS
        Creates a CIM session to a Dell DRAC device.

    .DESCRIPTION
        The NewDracCimSession cmdlet creates a CIM session to a Dell DRAC device using the specified computer name and credentials.

    .PARAMETER ComputerName
        Specifies the name of the Dell DRAC device to connect to.

    .PARAMETER Credential
        Specifies the credentials to use for connecting to the Dell DRAC device.

    .EXAMPLE
        $Credential = Get-Credential
        New-DracCimSession -ComputerName 'DRAC01' -Credential $Credential
        This command creates a CIM session to the Dell DRAC device named 'DRAC01' using the provided credentials.
    #>
    [OutputType("CimSession")]
    param (
        [parameter(Mandatory = $true)]
        [string] $ComputerName,

        [parameter(Mandatory = $true)]
        [pscredential] $Credential
    )

    $CimOptionParams = @{
        Encoding            = 'Utf8'
        SkipCACheck         = $true
        SkipCNCheck         = $true
        SkipRevocationCheck = $true
        UseSsl              = $true
    }
    $CimOptions = New-CimSessionOption @CimOptionParams

    $CimSessionParams = @{
        Authentication = 'Basic'
        ComputerName   = $ComputerName
        Credential     = $Credential
        Port           = 443
        SessionOption  = $CimOptions
    }
    $CimSession = New-CimSession @CimSessionParams

    Write-Output -InputObject $CimSession
}
