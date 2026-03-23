function Get-IISLogPath
{
    <#
    .SYNOPSIS
        Retrieve website logging path.

    .DESCRIPTION
        The Get-IISLogPath cmdlet retrieves the log file path for one or more websites configured on the target computer.

    .PARAMETER Identity
        Specifies a name of one or more websites.  Get-IISLogPath retrieves the logging path for the website specified.  If you do not specify this parameter, the cmdlet will return all configured sites.

    .EXAMPLE
        Get-IISLogPath
        Returns log path information for all sites

    .EXAMPLE
        Get-IISLogPath -Identity 'Default Web Site'
        Returns log path information for the 'Default Web Site'

    .EXAMPLE
        Get-IISLogPath -Identity 'Admin*'
        Returns log path information for all sites whose Name begin with 'Admin'

    .EXAMPLE
        Get-IISLogPath -Identity @('MySite1','MySite2')
        Returns log path information for the sites 'MySite1' and 'MySite2'

    .NOTES
        Author: Trent Willingham
        Check out my other projects on GitHub https://github.com/HashGambit97
    #>
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true)]
        [string[]]$Identity
    )

    begin
    {
        $WebsiteObjects = Get-Website
        $FilteredSites = @()
    }

    process
    {
        if ($Identity)
        {
            foreach ($SiteName in $Identity)
            {
                $FilteredSites += $WebsiteObjects | Where-Object { $PSItem.Name -like $SiteName }
            }
        }
        else
        {
            $FilteredSites = $WebsiteObjects
        }

        foreach ($Site in $FilteredSites)
        {
            $LogPath = "$($Site.logFile.directory)\W3SVC$($Site.id)"
            $LogPath = [System.Environment]::ExpandEnvironmentVariables($LogPath)

            $Object = New-Object -TypeName PSCustomObject -Property @{
                Id      = $Site.Id
                Name    = $Site.Name
                LogPath = $LogPath
            }
            $Object.PSObject.TypeNames.Insert(0, 'ServerManagement.IISLogPath')
            Write-Output -InputObject $Object
        }
    }
} #end function
