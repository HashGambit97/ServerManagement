# Changelog for ServerManagement

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- For new features.

### Changed

- For changes in existing functionality.

### Deprecated

- For soon-to-be removed features.

### Removed

- For now removed features.

### Fixed

- For any bug fix.

### Security

- In case of vulnerabilities.

# ServerManagement Release History

## v0.6.0 (2019-12-18)

### Changed

- `Invoke-LogRotation`: Added feature to remove old archive files
- `Register-LogRotationTask`: Added feature to remove old archive files


## v0.5.0 (2018-04-24)

### Added

  - The `Get-LinuxCdpInfo` cmdlet queries a Linux server for CDP information by capturing the network packets using tcpdump.
  - The `Install-DiskCleanupTool` cmdlet copies the Disk Cleanup executable and supporting files from the WinSxS folder the to correct installed location and creates the shortcut.

### Changed

  - `Invoke-LogRotation`: Refactored the parameter name 'CompressDays' to 'KeepRaw'
  - `Register-LogRotationTask`: Refactored the parameter name 'CompressDays' to 'KeepRaw'


## v0.4.0 (2017-04-05)

### Added

  - The `Disable-SChannelFeature` cmdlet disables features in the SChannel security suite on Windows computers.  This cmdlet can be used to disable ciphers, key exchanges, and protocols that are consider insecure.
  - The `Get-RDSession` cmdlet uses the Cassia.dll to query local or remote computers for active and disconnection Remote Desktop sessions.

### Changed

  - Updated the build process use utilize the InvokeBuild module.

## v0.3.0 (2017-02-17)

### Added
  - `Get-IISLogPath`: This function uses the WebAdministration module to query the IIS configuration and retreive the log file locations.

## v0.2.0 (2017-02-16)

### Added
  - `Invoke-LogRotation`: Compresses log files by month

## v0.1.0 (2017-02-15)

### Added
  - `Get-DfsrBacklogStatus`: Query DFSR replication backlog
