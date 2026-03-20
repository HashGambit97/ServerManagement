function Disable-SChannelFeature {
    <#
    .SYNOPSIS
        Disable SChannel featuers on one or more computers.
    .DESCRIPTION
        The Disable-SChannelFeature cmdlet disables features in the SChannel security suite on Windows computers.  This cmdlet can be used to disable ciphers, key exchanges, and protocols that are consider insecure.
    .EXAMPLE
        Disable-SChannelFeature -ComputerName 'MyServer' -Rc4
        Disable the RC4 cipher on the computer 'MyServer'.
    .INPUTS
        System.String
    .OUTPUTS
        None
    .LINK
        http://psservermanagement.readthedocs.io/en/latest/functions/Disable-SChannelFeature
    .NOTES
        Author: Trent Willingham
        Check out my other projects on GitHub https://github.com/twillin912
    #>
    [CmdletBinding(
        SupportsShouldProcess
    )]
    param(
        # Specifies the name of the system to target.
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [string[]]$ComputerName,

        # Disables all insecure SChannel features.
        [Parameter()]
        [switch]$All,

        # Disables SChannel 3DES cipher usage.
        [Parameter()]
        [switch]$3Des,

        # Disables SChannel Diffe-Hellman key exchange.
        [Parameter()]
        [switch]$Dhe,

        # Disables SChannel RC4 cipher usage.
        [Parameter()]
        [switch]$Rc4,

        # Disables SChannel SSL v2 protocol usage.
        [Parameter()]
        [switch]$Ssl2,

        # Disables SChannel SSL v3 protocol usage.
        [Parameter()]
        [switch]$Ssl3

    )

    begin {
        $SChannelKey = 'SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL'
        $Keys = @()
        if ($3Des -or $All) {
            $Keys += "$SChannelKey\Ciphers\Triple DES 168"
        }
        if ($Dhe -or $All) {
            $Keys += "$SChannelKey\KeyExchangeAlgorithms\Diffie-Hellman"
        }
        if ($Rc4 -or $All) {
            $Keys += "$SChannelKey\Ciphers\RC4 40/128"
            $Keys += "$SChannelKey\Ciphers\RC4 56/128"
            $Keys += "$SChannelKey\Ciphers\RC4 128/128"
        }
        if ($Ssl2 -or $All) {
            $Keys += "$SChannelKey\Protocols\SSL 2.0\Server"
        }
        if ($Ssl3 -or $All) {
            $Keys += "$SChannelKey\Protocols\SSL 3.0\Server"
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            if (!(Test-Connection -ComputerName $Computer -Count 1 -Quiet)) {
                throw "Cannot connect to computer '$Computer', because it is offline."
            }

            if ($PSCmdlet.ShouldProcess($Computer)) {
                try {
                    $RemoteReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', "$Computer")
                    foreach ($Key in $Keys) {
                        Write-Debug -Message "Update Registry Key: $Key"
                        $RemoteKey = $RemoteReg.CreateSubKey("$Key", $true)
                        $RemoteKey.SetValue('Enabled', 0, 'DWord')
                    }
                }
                catch {
                    Write-Error "Failed to update registry on '$Computer'.`n$_"
                    continue
                }
            }
        }
    }

    end {

    }
}
