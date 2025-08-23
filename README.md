# PsInstallTools

This module provides a set of simple functions that installs applications from executables, binaries, or folders.

## Getting Started

To import this module, run the below:

```powershell
git clone https://github.com/deltoss/PsInstallTools.git
Import-Module -Verbose "./PsInstallTools"
```

## Usage Examples

```powershell
# Install-ExeBinaryFromUrl should be used for binary executables.
# 1. Downloads from a repository release URL
# 2. Extracts the archive into a temporary directory
# 3. Copies the contents of an archive to an installation directory
# 4. Adds the installation directory to $PATH environment variable
Install-ExeBinaryFromUrl (Get-LatestGitHubRelease "zk-org/zk" "*windows-x86_64.tar.gz") "zk"

# Start-ExeFromUrl should be used for installer executables.
# 1. Downloads from a repository release URL
# 2. If an archive, extracts the archive into a temporary directory
# 3. Runs the exe file from extracted directory
Start-ExeFromUrl (Get-LatestGitHubRelease "Bill-Stewart/SyncthingWindowsSetup" "syncthing-windows-setup.exe")
```

## One-Off Usage

```powershell
$targetTempPath = "$((Get-Item $env:TEMP).FullName)/PsInstallTools"
if (Test-Path $targetTempPath) {
    Remove-Item -Path $targetTempPath -Recurse -Force
}
git clone https://github.com/deltoss/PsInstallTools.git $targetTempPath
Import-Module -Verbose $targetTempPath
Install-ExeBinaryFromUrl (Get-LatestGitHubRelease "zk-org/zk" "*windows-x86_64.tar.gz") "zk"
Remove-Module -Verbose PsInstallTools
Remove-Item -Path $targetTempPath -Recurse -Force
```

