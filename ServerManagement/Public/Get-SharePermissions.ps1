function Get-SharePermission {
    [CmdletBinding()]
    [OutputType('Win32_SecurityDescriptor')]
    param (
        [Parameter(Mandatory)]
        [string] $ShareName,

        [Parameter()]
        [string] $ComputerName = $env:COMPUTERNAME
    )

    begin {

    }

    process {
        $ShareSecuritySettings = Get-CimInstance -ComputerName $ComputerName -ClassName 'Win32_LogicalShareSecuritySetting'
        $ShareSecurity = $ShareSecuritySettings | Where-Object { $_.Name -eq $ShareName }
        if ($ShareSecurity) {
            (Invoke-CimMethod -InputObject $ShareSecurity -MethodName 'GetSecurityDescriptor').Descriptor
        }
    }

    end {

    }
}
