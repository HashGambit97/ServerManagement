function Register-LogRotationTask {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        # Specifies the name of the scheduled task with ' - LogRotation' appended.
        [Parameter(Mandatory, Position = 1)]
        [string] $Name,

        # Specifies a path to one or more locations.  Invoke-LogRotation processes the log files in the specified locations.
        [Parameter(Mandatory, Position = 2)]
        [string[]] $Path,

        # Specifies the number of days to keep uncompressed log files.  If you do not specify this parameter, the cmdlet will retain 5 days.
        [Parameter(Position = 3)]
        [Alias('CompressDays')]
        [int] $KeepRaw,

        # Specifies the number of months to keep compresses log archives.  If you do not specify this parameter, the archives will be retained indefinately.
        [Parameter()]
        [int] $KeepArchives,

        # Specifies the start time for the scheduled task.  The default value is 10:00 PM.
        [Parameter()]
        [string] $StartTime = '22:00',

        # Specifies a wildcard selection string of files to include.
        [Parameter()]
        [string]$Include,

        # Specifies a wildcard selection string of files to exclude.
        [Parameter()]
        [string]$Exclude
    )

    $Command = "Invoke-LogRotation -Path '$Path'"
    if ($KeepRaw) {
        $Command += " -KeepRaw $KeepRaw"
    }
    if ($KeepArchives) {
        $Command += " -KeepArchvies $KeepArchives"
    }
    if ($Include) {
        $Command += " -Include '$Include'"
    }
    if ($Exclude) {
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
