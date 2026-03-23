function Get-ComputerSerialNumber
{
    <#
    .SYNOPSIS
        Get the serial number of one or more computers.

    .DESCRIPTION
        The Get-ComputerSerialNumber cmdlet retrieves the serial number of one or more computers.

    .PARAMETER ComputerName
        Specifies the name of the system to target.

    .PARAMETER Credential
        Specifies the credential to use for connecting to the remote computer.

    .PARAMETER Linux
        Use SSH to connect to a Linux system.

    .EXAMPLE
        Get-ComputerSerialNumber -ComputerName 'MyServer'
        Get the serial number for the computer 'MyServer'.

    .NOTES
        Author: Trent Willingham
        Check out my other projects on GitHub https://github.com/HashGambit97
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [parameter(Mandatory = $true)]
        [string[]] $ComputerName,

        [parameter(
            ParameterSetName = 'Default',
            Mandatory = $false)]
        [parameter(
            ParameterSetName = 'Linux',
            Mandatory = $true)]
        [pscredential] $Credential,

        [parameter(ParameterSetName = 'Linux')]
        [switch] $Linux
    )

    process
    {
        foreach ($Computer in $ComputerName)
        {
            if (!(Test-Connection -ComputerName $Computer -Count 1 -Quiet))
            {
                Write-Warning -Message "Could not connect to '$Computer', because the machine is offline."
                continue
            }

            if (!$Linux)
            {
                Write-Verbose -Message "Connecting to '$Computer' using WinRM session."
                try
                {
                    $Session = New-CimSession -ComputerName $Computer
                    $Return = Get-CimInstance -CimSession $Session -ClassName Win32_Bios
                    New-Object -TypeName PSObject -Property @{
                        'Name'         = $Computer
                        'SerialNumber' = $Return.SerialNumber
                    }
                }
                catch
                {
                    throw
                }
                finally
                {
                    if ($Session)
                    {
                        $null = Remove-CimSession -CimSession $Session
                    }
                }
            }
            else
            {
                Write-Verbose -Message "Connecting to '$Computer' using SSH session."
                try
                {
                    $Session = New-SSHSession -ComputerName $Computer -Credential $Credential -AcceptKey
                    $Return = Invoke-SSHCommand -SSHSession $Session -Command 'dmidecode | grep "Serial Number" | head -n 1'
                    $SerialNumber = $Return.Output[0].Split(':')[1].Trim()
                    New-Object -TypeName PSObject -Property @{
                        'Name'         = $Computer
                        'SerialNumber' = $SerialNumber
                    }
                }
                catch
                {
                    throw
                }
                finally
                {
                    if ($Session)
                    {
                        $null = Remove-SSHSession -SSHSession $Session
                    }
                }
            }
        }
    }
}
