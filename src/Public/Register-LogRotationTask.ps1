function Register-LogRotationTask
{
    <#
    .SYNOPSIS
        Registers a scheduled task to run the Invoke-LogRotation cmdlet.

    .DESCRIPTION
        The Register-LogRotationTask cmdlet registers a scheduled task to run the Invoke-LogRotation cmdlet with the specified parameters.


    .PARAMETER Name
        The name of the log rotation task. This will be used in the scheduled task name and should be descriptive of the logs being rotated.

    .PARAMETER Path
        The path(s) to the log files to be rotated. This parameter accepts one or more paths.

    .PARAMETER KeepRaw
        The number of days to keep raw log files before deletion.

    .PARAMETER KeepArchives
        The number of archived log files to keep before deletion.

    .PARAMETER StartTime
        The time of day to run the log rotation task. Default is '22:00'

    .PARAMETER Include
        A string or regex pattern to include specific log files in the rotation process.

    .PARAMETER Exclude
        A string or regex pattern to exclude specific log files from the rotation process.

    .EXAMPLE
        Register-LogRotationTask -Name 'IIS Logs' -Path C:\Inetpub\Logs\LogFiles\W3SVC1
        This command registers a scheduled task named 'LogRotation - IIS Logs' to run the Invoke-LogRotation cmdlet with the specified path and default retention settings.

    .NOTES
        Author: Trent Willingham
        Check out my other projects on GitHub https://github.com/HashGambit97
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string] $Name,

        [Parameter(Mandatory, Position = 2)]
        [string[]] $Path,

        [Parameter(Position = 3)]
        [Alias('CompressDays')]
        [int] $KeepRaw,

        [Parameter()]
        [int] $KeepArchives,

        [Parameter()]
        [string] $StartTime = '22:00',

        [Parameter()]
        [string]$Include,

        [Parameter()]
        [string]$Exclude
    )

    $Command = "Invoke-LogRotation -Path '$Path'"
    if ($KeepRaw)
    {
        $Command += " -KeepRaw $KeepRaw"
    }
    if ($KeepArchives)
    {
        $Command += " -KeepArchives $KeepArchives"
    }
    if ($Include)
    {
        $Command += " -Include '$Include'"
    }
    if ($Exclude)
    {
        $Command += " -Exclude '$Exclude'"
    }

    $TaskParams = @{
        TaskName = "LogRotation - $Name"
        Trigger  = New-ScheduledTaskTrigger -At $StartTime -Daily
        User     = 'NT AUTHORITY\SYSTEM'
        Action   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NonInteractive -NoProfile -WindowStyle Hidden -Command `"$Command`""
    }
    Register-ScheduledTask @TaskParams -Force
}
