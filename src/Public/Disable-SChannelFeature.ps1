function Disable-SChannelFeature
{
    <#
    .SYNOPSIS
        Disable server side SChannel features on one or more computers.
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
        Check out my other projects on GitHub https://github.com/HashGambit97
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

        # Disables SChannel Diffie-Hellman key exchange.
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
        [switch]$Ssl3,

        # Disables SChannel TLS v1.0 protocol usage.
        [Parameter()]
        [switch]$Tls1,

        # Disables SChannel TLS v1.1 protocol usage.
        [Parameter()]
        [switch]$Tls11
    )

    begin
    {
        $SChannelKey = 'SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL'
        $KeysToDisable = @()
        if ($Rc4 -or $All)
        {
            Write-Verbose "Adding RC4 cipher to list of features to disable."
            $KeysToDisable += "$SChannelKey\Ciphers\RC4 40/128"
            $KeysToDisable += "$SChannelKey\Ciphers\RC4 56/128"
            $KeysToDisable += "$SChannelKey\Ciphers\RC4 128/128"
        }
        if ($3Des -or $All)
        {
            Write-Verbose "Adding 3DES cipher to list of features to disable."
            $KeysToDisable += "$SChannelKey\Ciphers\Triple DES 168"
        }
        if ($Dhe -or $All)
        {
            Write-Verbose "Adding Diffie-Hellman key exchange to list of features to disable."
            $KeysToDisable += "$SChannelKey\KeyExchangeAlgorithms\Diffie-Hellman"
        }
        if ($Ssl2 -or $All)
        {
            Write-Verbose "Adding SSL v2 protocol to list of features to disable."
            $KeysToDisable += "$SChannelKey\Protocols\SSL 2.0\Server"
        }
        if ($Ssl3 -or $All)
        {
            Write-Verbose "Adding SSL v3 protocol to list of features to disable."
            $KeysToDisable += "$SChannelKey\Protocols\SSL 3.0\Server"
        }
        if ($Tls1 -or $All)
        {
            Write-Verbose "Adding TLS v1.0 protocol to list of features to disable."
            $KeysToDisable += "$SChannelKey\Protocols\TLS 1.0\Server"
        }
        if ($Tls11 -or $All)
        {
            Write-Verbose "Adding TLS v1.1 protocol to list of features to disable."
            $KeysToDisable += "$SChannelKey\Protocols\TLS 1.1\Server"
        }
    }

    process
    {
        foreach ($Computer in $ComputerName)
        {
            if (!(Test-Connection -ComputerName $Computer -Count 1 -Quiet))
            {
                throw "Cannot connect to computer '$Computer', because it is offline."
            }

            if ($PSCmdlet.ShouldProcess($Computer))
            {
                try
                {
                    $RemoteReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', "$Computer")
                    foreach ($Key in $KeysToDisable)
                    {
                        Write-Debug -Message "Update Registry Key: $Key"
                        $RemoteKey = $RemoteReg.CreateSubKey("$Key", $true)
                        $RemoteKey.SetValue('Enabled', 0, 'DWord')
                    }
                }
                catch
                {
                    Write-Error "Failed to update registry on '$Computer'.`n$_"
                    continue
                }
            }
        }
    }

    end
    {

    }
}
