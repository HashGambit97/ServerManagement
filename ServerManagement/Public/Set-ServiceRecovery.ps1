function Set-ServiceRecovery {
    [CmdletBinding(
        DefaultParameterSetName = 'Name',
        SupportsShouldProcess
    )]
    param (
        [parameter(
            Mandatory,
            ParameterSetName = 'Name',
            Position = 0,
            ValueFromPipeline
        )]
        [string] $Name,

        [parameter(
            Mandatory,
            ParameterSetName = 'DisplayName',
            Position = 0,
            ValueFromPipeline
        )]
        [string] $DisplayName,

        [parameter()]
        [string] $ComputerName = '.',

        [parameter(Mandatory)]
        [ValidateSet('NoAction', 'RunProgram', 'Restart', 'Reboot')]
        [string] $FirstAction,

        [parameter()]
        [ValidateSet('NoAction', 'RunProgram', 'Restart', 'Reboot')]
        [string] $SecondAction = 'NoAction',

        [parameter()]
        [ValidateSet('NoAction', 'RunProgram', 'Restart', 'Reboot')]
        [string] $SubsequentAction = 'NoAction',

        [parameter()]
        [int] $RestartTime = 60,

        [parameter()]
        [int] $ResetCounter = 1


    )

    begin {
        $CimSession = New-CimSession -ComputerName $ComputerName
        $ActionStatement = @($FirstAction, $RestartTime, $SecondAction, $RestartTime, $SubsequentAction, $RestartTime) -join "/"
    }

    process {
        $AllServices = Get-CimInstance -CimSession $CimSession -ClassName 'Win32_Service'
        switch ($PSCmdlet.ParameterSetName) {
            'DisplayName' {
                $Services = $AllServices | Where-Object { $_.DisplayName -match $DisplayName }
            }
            default {
                $Services = $AllServices | Where-Object { $_.Name -match $Name }
            }
        }
        foreach ($Service in $Services) {
            $Result = sc.exe "\\$ComputerName" failure $($Service.Name) actions= $ActionStatement reset= ($ResetCounter * 86400)
            $Result
        }
    }

    end {
        $CimSession.Close()
    }
}
