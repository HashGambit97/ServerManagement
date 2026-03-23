function Get-ComputerDetail
{
    <#
    .SYNOPSIS
        Get physical computer specs.

    .DESCRIPTION
        The Get-ComputerDetail cmdlet retrieves physical computer specifications from one or more computers.  This cmdlet can be used to quickly inventory hardware details across a network.

    .PARAMETER ComputerName
        Specifies the name of the system to target.

    .PARAMETER Credential
        Specifies the credentials to use for connecting to the remote computer.

    .EXAMPLE
        Get-ComputerDetail -ComputerName 'MyServer'
        Get the computer details for the computer 'MyServer'.

    .NOTES
        Author: Trent Willingham
        Check out my other projects on GitHub https://github.com/HashGambit97
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $ComputerName,

        [parameter()]
        [pscredential] $Credential
    )

    begin
    {
        $SessionParams = @{}
    }

    process
    {
        if ($Credential)
        {
            $SessionParams.Credential = $Credential
        }

        foreach ($Computer in $ComputerName)
        {
            $SessionParams.ComputerName = $Computer
            try
            {
                $Session = NewFallbackCimSession @SessionParams

                $Bios = Get-CimInstance -CimSession $Session -ClassName 'Win32_Bios'
                $Memory = Get-CimInstance -CimSession $Session -ClassName 'Win32_PhysicalMemory'
                $OS = Get-CimInstance -CimSession $Session -ClassName 'Win32_OperatingSystem'
                $Proc = Get-CimInstance -CimSession $Session -ClassName 'Win32_Processor'
                $System = Get-CimInstance -CimSession $Session -ClassName 'Win32_ComputerSystem'
            }
            catch
            {
                Write-Warning -Message "An error occurred connecting to '$Computer'.  Skipping."
                continue
            }
            finally
            {
                if ($Session)
                {
                    $Session.Close()
                    Remove-Variable -Name Session
                }
            }

            $OutputObject = [PSCustomObject] @{
                'ComputerName'    = $Computer
                'SerialNumber'    = $Bios.SerialNumber
                'Model'           = $System.Model
                'CpuSockets'      = ($Proc | Measure-Object).Count
                'CpuCores'        = ($Proc | Measure-Object -Sum -Property 'NumberOfCores').Sum
                'CpuClockSpeed'   = ($Proc | Measure-Object -Property MaxClockSpeed -Maximum).Maximum
                'Dimms'           = ($Memory | Measure-Object).Count
                'Memory'          = ($Memory | Measure-Object -Sum -Property 'Capacity').Sum
                'OperatingSystem' = $OS.Caption
                'InstallDate'     = [datetime]$OS.InstallDate
            }
            $OutputObject.PSObject.TypeNames.Insert(0, 'ServerManagement.ComputerDetail')
            Write-Output -InputObject $OutputObject
        }
    }

    end
    {
    }
}
