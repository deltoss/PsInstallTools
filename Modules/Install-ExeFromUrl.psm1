# Generic Archive Downloader and Installer
# Downloads an archive from a URL, extracts it, installs to %LOCALAPPDATA%/Programs, and adds to PATH
#
# Usage:
#   Install-ExeFromUrl <url> <app_name> [exe_pattern] [working_dir] [archive_filename]
#
# Examples:
#   Install-ExeFromUrl "https://example.com/myapp.zip" "MyApp"
#   Install-ExeFromUrl (Get-LatestGitHubRelease "zk-org/zk" "*windows-x86_64.tar.gz") "zk"
#   Install-ExeFromUrl "https://example.com/app.tar.gz" "MyApp" "myapp.exe"
#   Install-ExeFromUrl "https://example.com/file.7z" "MyApp" "*.exe" "C:\temp"

function Install-ExeFromUrl {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Url,

        [Parameter(Position=1, Mandatory=$true)]
        [string]$AppName,

        [Parameter(Position=2)]
        [string]$ExePattern = "*.exe",

        [Parameter(Position=3)]
        [string]$WorkingDir = "$env:TEMP/InstallExeUrl/",

        [Parameter(Position=4)]
        [string]$ArchiveFileName = ""
    )

    Import-Module "./Modules/InstallTools/InstallTools.psm1"
    Import-Module "$PSScriptRoot/Install-FromFolder.psm1"

    function Get-FileNameFromUrl {
        param($Url)

        try {
            $uri = [System.Uri]$Url
            $fileName = [System.IO.Path]::GetFileName($uri.LocalPath)

            if ([string]::IsNullOrEmpty($fileName) -or $fileName -eq "/") {
                throw "Cannot determine filename from URL. Please provide a filename using the 5th parameter."
            }

            return $fileName
        }
        catch {
            throw "Cannot determine filename from URL '$Url'. Please provide a filename using the 5th parameter."
        }
    }

    # Create working directory
    New-Item -Path $WorkingDir -ItemType Directory -Force | Out-Null

    Write-Host "Starting download and installation process for '$AppName'..." -ForegroundColor Green

    # Determine filename
    if ($ArchiveFileName -eq "") {
        try {
            $fileName = Get-FileNameFromUrl -Url $Url
        }
        catch {
            Write-Error $_
            exit 1
        }
    } else {
        $fileName = $ArchiveFileName
    }

    Write-Host "Downloading from: $Url" -ForegroundColor Yellow
    Write-Host "Filename: $fileName" -ForegroundColor Yellow

    $archivePath = Join-Path $WorkingDir $fileName
    $extractDir = Join-Path $WorkingDir "extracted_$(Get-Random)"

    # Download the archive
    Write-Host "Downloading $fileName..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $Url -OutFile $archivePath
        Write-Host "Downloaded successfully to: $archivePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download: $_"
        exit 1
    }

    # Create extraction directory
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

    # Extract the archive
    Write-Host "Extracting archive..." -ForegroundColor Yellow
    try {
        Export-Archive -ArchivePath $archivePath -ExtractDir $extractDir
    }
    catch {
        Write-Error "Failed to extract: $_"
        Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }

    # Verify we have executable files
    $exeFiles = Get-ChildItem -Path $extractDir -Filter $ExePattern -Recurse
    if ($exeFiles.Count -eq 0) {
        Write-Error "No exe file found matching pattern: $ExePattern"
        Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }

    Write-Host "Found $($exeFiles.Count) executable file(s) matching pattern '$ExePattern'" -ForegroundColor Green

    # Install the application using the module function
    Write-Host "Installing application..." -ForegroundColor Yellow
    try {
        $installArgs = @{
            SourceFolder = $extractDir
            AppName = $AppName
        }

        Install-FromFolder @installArgs
    }
    catch {
        Write-Error "Installation failed: $_"
        Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }

    # Clean up temporary files
    Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
    Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
    Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Process completed! '$AppName' has been installed and is ready to use." -ForegroundColor Green
}

Export-ModuleMember -Function Install-ExeFromUrl
