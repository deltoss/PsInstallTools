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
# Install-ExeFromUrl should be used for binary executables.
# 1. Downloads from a repository release URL
# 2. Extracts the archive into a temporary directory
# 3. Copies the contents of an archive to an installation directory
# 4. Adds the installation directory to $PATH environment variable
Install-ExeFromUrl (Get-LatestGitHubRelease "zk-org/zk" "*windows-x86_64.tar.gz") "zk"

# Start-ExeFromUrl should be used for installer executables.
# 1. Downloads from a repository release URL
# 2. Extracts the archive into a temporary directory
# 3. Runs the exe file from extracted directory
Start-ExeFromUrl (Get-LatestGitHubRelease "zk-org/zk" "*windows-x86_64.tar.gz")
```

## One-Off Usage

```powershell
git clone https://github.com/deltoss/PsInstallTools.git ./temp/PsInstallTools
Import-Module -Verbose "./temp/PsInstallTools"
Install-ExeFromUrl (Get-LatestGitHubRelease "zk-org/zk" "*windows-x86_64.tar.gz") "zk"
Remove-Module -Verbose PsInstallTools
Remove-Item -Path ./temp -Recurse -Force
```

