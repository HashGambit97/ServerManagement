function NewDracCimSession {
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
