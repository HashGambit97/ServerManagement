function NewFallbackCimSession
{
    <#
    .SYNOPSIS
        Creates a fallback CIM session to a remote computer.

    .DESCRIPTION
        The NewFallbackCimSession cmdlet creates a CIM session to a remote computer using either WSMAN or DCOM protocol, depending on the available connectivity.

    .PARAMETER ComputerName
        Specifies the name of the computer to connect to.

    .PARAMETER Credential
        Specifies the credentials to use for connecting to the computer.

    .EXAMPLE
        NewFallbackCimSession -ComputerName 'RemoteServer' -Credential (Get-Credential)
        This command creates a CIM session to the computer named 'RemoteServer' using the provided credentials. The cmdlet will attempt to connect using WSMAN protocol first and fall back to DCOM if WSMAN is not available.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ComputerName,

        [Parameter()]
        [pscredential] $Credential
    )

    begin
    {
        $SessionOptions = New-CimSessionOption -Protocol Dcom
        $SessionParams = @{
            'ErrorAction' = 'Stop'
        }

        if ($Credential)
        {
            $SessionParams.Credential = $Credential
        }
    }

    process
    {
        $SessionParams.ComputerName = $ComputerName
        if ((Test-WSMan -ComputerName $ComputerName -ErrorAction SilentlyContinue).ProductVersion -match 'Stack: ([3-9]|[1-9][0-9]+)\.[0-9]+')
        {
            try
            {
                Write-Verbose -Message "Attempting connection to '$ComputerName' using WSMAN protocol"
                $CimSession = New-CimSession @SessionParams
                Write-Output -InputObject $CimSession
            }
            catch
            {
                throw "Could not create remote CIM connection to '$ComputerName' using WSMAN protocol."
            }
        }
        else
        {
            $SessionParams.SessionOption = $SessionOptions
            try
            {
                Write-Verbose -Message "Attempting connection to '$ComputerName' using DCOM protocol"
                $CimSession = New-CimSession @SessionParams
                Write-Output -InputObject $CimSession
            }
            catch
            {
                throw "Could not create remote CIM connection to '$ComputerName' using DCOM protocol."
            }
        }
    }
}
