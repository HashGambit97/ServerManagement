function Install-DiskCleanupTool {
    <#
    .SYNOPSIS
        Install Disk Cleanup utlility.
    .DESCRIPTION
        Copies the Disk Cleanup utility and supporting files from the WinSxS folder on the system to the installed locations and created a shortcut in the Administrative Tools folder.
    .EXAMPLE
        Install-DiskCleanupTools
        Installs the Disk Cleanup utility on the local system.
    .EXAMPLE
        Install-DiskCleanupTools -ComputerName Server01
        Installs the Disk Cleanup utility on the system named 'Server01'.
    .INPUTS
        ComputerName as String or Array of strings
    .OUTPUTS
        None
    .LINK
        http://psservermanagement.readthedocs.io/en/latest/functions/Install-DiskCleanupTool
    .NOTES
        Author: Trent Willingham
        Check out my other projects on GitHub https://github.com/twillin912
    #>
    [CmdletBinding()]
    param (
        # Specifies the name of the computer to query.  Default value is the local computer.
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]] $ComputerName = 'localhost',

        [parameter()]
        [PSCredential] $Credential
    )

    begin {
        $InstanceParams = @{
            'Class'     = 'Win32_OperatingSystem'
            'Namespace' = 'root\cimv2'
        }

        $SessionParams = @{
            'ErrorAction' = 'Stop'
        }

        if ($Credential) {
            $CimParams.Credential = $Credential
        }

        $CreateLink = {
            $Link = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Administrative Tools\Disk Cleanup.lnk"
            $Target = '%windir%\system32\cleanmgr.exe'

            $NewShortcut = (New-Object -ComObject 'Wscript.Shell').CreateShortcut($Link)
            $NewShortcut.Description = 'Enables you to clear your disk of unnecessary files.'
            $NewShortcut.IconLocation = "%windir%\system32\cleanmgr.exe, 0"
            $NewShortcut.TargetPath = $Target
            $NewShortcut.Save()
        }

        $RemoteCopy = {
            param ($Source, $Target)
            Copy-Item $Source $Target -Force
        }

    }

    process {
        foreach ($Computer in $ComputerName) {
            $Supported = $true
            $CimParams.ComputerName = $Computer
            try {
                $CimSession = NewFallbackCimSession @SessionParams
                $OperatingSystem = Get-CimInstance -CimSession $CimSession @InstanceParams
                $WindowsDir = $OperatingSystem.WindowsDirectory
                $WindowsVersion = $OperatingSystem.Version
            }
            catch {
                throw
            }
            finally {
                if ($CimSession) {
                    $CimSession.Close()
                }
            }

            switch -Wildcard ($WindowsVersion) {
                "6.2.*" {
                    $ExeSource = "$WindowsDir\WinSxS\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.2.9200.16384_none_c60dddc5e750072a\cleanmgr.exe"
                    $MuiSource = "$WindowsDir\WinSxS\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.2.9200.16384_en-us_b6a01752226afbb3\cleanmgr.exe.mui"
                }
                "6.1.*" {
                    $ExeSource = "$WindowsDir\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe"
                    $MuiSource = "$WindowsDir\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_en-us_b9cb6194b257cc63\cleanmgr.exe.mui"
                }
                "6.0.*" {
                    $ExeSource = "$WindowsDir\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.0.6001.18000_none_c962d1e515e94269\cleanmgr.exe"
                    $MuiSource = "$WindowsDir\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.0.6001.18000_en-us_b9f50b71510436f2\cleanmgr.exe.mui"
                }
                Default {
                    $Supported = $false
                }
            }

            if (!($Supported)) {
                Write-Warning -Message "The operating system '$WindowsVersion' is not supported."
                $CimSession.Close()
                break
            }

            $ExeTarget = "$env:SystemRoot\System32"
            $MuiTarget = "$env:SystemRoot\System32\en-US"

            Invoke-Command @SessionParams -ScriptBlock $RemoteCopy -ArgumentList @($ExeSource, $ExeTarget)
            Invoke-Command @SessionParams -ScriptBlock $RemoteCopy -ArgumentList @($MuiSource, $MuiTarget)
            Invoke-Command @SessionParams -ScriptBlock $CreateLink
        }
    }

    end {
    }
}
