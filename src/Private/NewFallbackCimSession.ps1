function NewFallbackCimSession {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ComputerName,

        [Parameter()]
        [pscredential] $Credential
    )

    begin {
        $SessionOptions = New-CimSessionOption -Protocol Dcom
        $SessionParams = @{
            'ErrorAction' = 'Stop'
        }

        if ($Credential) {
            $SessionParams.Credential = $Credential
        }
    }

    process {
        $SessionParams.ComputerName = $ComputerName
        if ((Test-WSMan -ComputerName $ComputerName -ErrorAction SilentlyContinue).ProductVersion -match 'Stack: ([3-9]|[1-9][0-9]+)\.[0-9]+') {
            try {
                Write-Verbose -Message "Attempting connection to '$ComputerName' using WSMAN protocol"
                $CimSession = New-CimSession @SessionParams
                Write-Output -InputObject $CimSession
            }
            catch {
                throw "Could not create remote CIM connection to '$ComputerName' using WSMAN protocol."
            }
        }
        else {
            $SessionParams.SessionOption = $SessionOptions
            try {
                Write-Verbose -Message "Attempting connection to '$ComputerName' using DCOM protocol"
                $CimSession = New-CimSession @SessionParams
                Write-Output -InputObject $CimSession
            }
            catch {
                throw "Could not create remote CIM connection to '$ComputerName' using DCOM protocol."
            }
        }
    }
}
