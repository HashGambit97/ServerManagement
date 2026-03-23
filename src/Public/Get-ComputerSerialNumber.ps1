function Get-ComputerSerialNumber {
    <#
    #>
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        # Parameter help description
        [parameter(Mandatory = $true)]
        [string[]] $ComputerName,

        # Parameter help description
        [parameter(
            ParameterSetName='Default',
            Mandatory = $false)]
        [parameter(
            ParameterSetName='Linux',
            Mandatory = $true)]
        [pscredential] $Credentials,

        [parameter(ParameterSetName='Linux')]
        [switch] $Linux
    )

    process {
        foreach ($Computer in $ComputerName) {
            if (!(Test-Connection -ComputerName $Computer -Count 1 -Quiet)) {
                Write-Warning -Message "Could not connect to '$Computer', because the machine is offline."
                continue
            }

            if (!$Linux) {
                Write-Verbose -Message "Connecting to '$Computer' using WinRM session."
                try {
                    $Session = New-CimSession -ComputerName $Computer
                    $Return = Get-CimInstance -CimSession $Session -ClassName Win32_Bios
                    New-Object -TypeName PSObject -Property @{
                        'Name' = $Computer
                        'SerialNumber' = $Return.SerialNumber
                    }
                }
                catch {
                    throw
                }
                finally {
                    if ($Session) {
                        $null = Remove-CimSession -CimSession $Session
                    }
                }
            } #if
            else {
                Write-Verbose -Message "Connecting to '$Computer' using SSH session."
                try {
                    $Session = New-SSHSession -ComputerName $Computer -Credential $Credentials -AcceptKey
                    $Return = Invoke-SSHCommand -SSHSession $Session -Command 'dmidecode | grep "Serial Number" | head -n 1'
                    $SerialNumber = $Return.Output[0].Split(':')[1].Trim()
                    New-Object -TypeName PSObject -Property @{
                        'Name' = $Computer
                        'SerialNumber' = $SerialNumber
                    }
                }
                catch {
                    throw
                }
                finally {
                    if ($Session) {
                        $null = Remove-SSHSession -SSHSession $Session
                    }
                }
            } #else
        }
    }
}
