function Set-SharePermission {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ShareName,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [object] $SecurityDescriptor,

        [Parameter()]
        [string] $ComputerName = $env:COMPUTERNAME
    )

    begin {

    }

    process {
        $ShareSecuritySettings = Get-CIMInstance -ComputerName $ComputerName -ClassName 'Win32_LogicalShareSecuritySetting'
        $ShareSecurity = $ShareSecuritySettings | Where-Object { $_.Name -eq $ShareName }
        $Response = Invoke-CimMethod -InputObject $ShareSecurity -MethodName 'SetSecurityDescriptor' -Arguments @{Descriptor = $SecurityDescriptor}
        $Response
    }

    end {

    }
}
