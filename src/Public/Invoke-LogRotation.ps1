function Invoke-LogRotation {
    <#
    .SYNOPSIS
        Compresses log files by month.
    .DESCRIPTION
        The Invoke-LogRotation cmdlet retrieves a list of log file in the specified locations and compressed them into a ZIP archive by month.  Once the contents of the archive are verified the original log files are deleted.
    .EXAMPLE
        Invoke-LogRotation -Path C:\Inetpub\Logs\LogFiles\W3SVC1
        Archives the log files for the IIS 'Default Website' using the default 5 day retention
    .EXAMPLE
        Invoke-LogRotation -Path C:\Inetpub\Logs\LogFiles\W3SVC1 -KeepRaw 10
        Archives the log files for the IIS 'Default Website' using the specified 10 day retention
    .LINK
        http://psservermanagement.readthedocs.io/en/latest/functions/Invoke-LogRotation
    .NOTES
        Author: Trent Willingham
        Check out my other projects on GitHub https://github.com/twillin912
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # Specifies a path to one or more locations.  Invoke-LogRotation processes the log files in the specified locations.
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$Path,

        # Specifies the number of days to keep uncompressed log files.  If you do not specify this parameter, the cmdlet will retain 5 days.
        [Parameter(Position = 1)]
        [Alias('CompressDays')]
        [int] $KeepRaw = 5,

        # Specifies the number of months to keep compresses log archives.  If you do not specify this parameter, the archives will be retained indefinately.
        [Parameter()]
        [int] $KeepArchives,

        # Specifies a wildcard selection string of files to include.
        [Parameter()]
        [string]$Include = '*.log',

        # Specifies a wildcard selection string of files to exclude.
        [Parameter()]
        [string]$Exclude
    )

    begin {
        $DateDisplayFormat = 'MM/dd/yyyy'
        $DateFileFormat = 'yyyy-MM'
        $CurrentDate = Get-Date -Hour 0 -Minute 0 -Second 0

        if ($KeepRaw) {
            $CompressBefore = (Get-Date -Date $CurrentDate).AddDays( - $KeepRaw)
        }

        if ($KeepArchives) {
            $DeleteBefore = (Get-Date -Date $CurrentDate).AddMonths( - $KeepArchives)
        }

        $AdditionalParams = @{ 'Include' = $Include }
        if ($Exclude) { $AdditionalParams.Add('Exclude', $Exclude) }

        $null = [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")

    }

    process {
        foreach ($LogPath in $Path) {
            if (!(Test-Path -Path $LogPath)) {
                Write-Error -Message "Cannot find path '$LogPath' because it does not exist."
                break
            }

            $LogFolder = Split-Path -Path $($LogPath) -Leaf

            if ($KeepRaw -and $KeepRaw -gt 0) {
                $LogsToCompress = Get-ChildItem -Path $LogPath @AdditionalParams -Recurse |
                Where-Object { $PSItem.PSIsContainer -eq $false -and $PSItem.LastWriteTime -lt $CompressBefore }
                Write-Verbose -Message "Compressing $($LogsToCompress.Count) older than $($CompressBefore.ToString($DateDisplayFormat))"

                $LogHashTable = @{ }
                foreach ($File in $LogsToCompress) {
                    $LogHashTable.Add($File.FullName, $File.LastWriteTime.ToString($DateFileFormat))
                }
                $LogHashTable = $LogHashTable.GetEnumerator() | Sort-Object -Property Value, Name
                $MonthsToProcess = @( $LogHashTable | Group-Object -Property Value | Select-Object -Property Name)

                foreach ($Month in $MonthsToProcess) {
                    $ZipFileName = "$($env:ComputerName)-$($LogFolder)-$($Month.Name).zip"
                    $ZipFullName = Join-Path -Path $LogPath -ChildPath $ZipFileName
                    $CurrentMonthLogs = $LogHashTable | Where-Object { $PSItem.Value -eq "$($Month.Name)" }

                    foreach ($LogFile in $CurrentMonthLogs) {
                        $LogName = Split-Path -Path $LogFile.Name -Leaf

                        if ($PSCmdlet.ShouldProcess($ZipFullName, "Create/Update Archive")) {
                            $ZipFile = [System.IO.Compression.ZipFile]::Open($ZipFullName, "Update")
                        }

                        if ($PSCmdlet.ShouldProcess($LogFile.Name, "Get Content")) {
                            $LogContent = Get-Content -LiteralPath $LogFile.Name -Raw
                        }

                        if (!($ZipFile.GetEntry($LogName))) {
                            if ($PSCmdlet.ShouldProcess($LogFile.Name, "Add to Archive")) {
                                $ZipFileEntry = $ZipFile.CreateEntry($LogName)
                                $StreamWriter = [System.IO.StreamWriter]$ZipFileEntry.Open()
                                $StreamWriter.Write($LogContent)
                                $StreamWriter.Dispose()
                                $ZipFileEntry.LastWriteTime = (Get-Item -LiteralPath "$($LogFile.Name)").LastWriteTime
                            }
                        }

                        if ($PSCmdlet.ShouldProcess($ZipFullName, "Save Archive")) {
                            $ZipFile.Dispose()
                        }

                        if ($PSCmdlet.ShouldProcess($LogFile.Name, "Compare to Archive")) {
                            $ZipFile = [System.IO.Compression.ZipFile]::Open($ZipFullName, "Read")
                            $ZipFileEntry = [System.IO.StreamReader]$ZipFile.GetEntry($LogName).Open()
                            $ZipContent = $ZipFileEntry.ReadToEnd()
                            $ZipFile.Dispose()

                            if ($ZipContent -eq $LogContent -or $LogContent.Length -eq 0) {
                                Remove-Item -LiteralPath $LogFile.Name
                            }
                        }
                        [System.GC]::Collect()
                    }
                }
            }

            if ($KeepArchives -and $KeepArchives -gt 0) {
                $LogArchives = Get-ChildItem -Path $LogPath -Filter "$($env:ComputerName)-$($LogFolder)-*.zip"
                $ArchivesToDelete = $LogArchives | Where-Object { $_.LastWriteTime -lt $DeleteBefore }
                foreach ($Archive in $ArchivesToDelete) {
                    if ($PSCmdlet.ShouldProcess($Archive.Name, 'Delete Archive')){
                        Remove-Item -Path $Archive.FullName
                    }
                }
            }
        }
    }

    end {

    }
}
