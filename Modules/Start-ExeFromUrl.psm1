# Generic Archive Downloader and Runner
# Downloads an archive from a URL, extracts it, runs the first matching exe, then cleans up
#
# Usage:
#   Start-ExeFromUrl <url> [exe_pattern] [working_dir] [archive_filename]
#
# Examples:
#   Start-ExeFromUrl "https://example.com/myapp.zip"
#   Start-ExeFromUrl (Get-LatestGitHubRelease "zk-org/zk" "*windows-x86_64.tar.gz")
#   Start-ExeFromUrl "https://example.com/app.tar.gz" "myapp.exe"
#   Start-ExeFromUrl "https://example.com/file.7z" "*.exe" "C:\temp"
#   Start-ExeFromUrl "https://example.com/download?id=123" "*.exe" $env:TEMP "custom.zip"

function Start-ExeFromUrl {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Url,

        [Parameter(Position=1)]
        [string]$ExePattern = "*.exe",

        [Parameter(Position=2)]
        [string]$WorkingDir = "$env:TEMP/StartExeFromUrl/",

        [Parameter(Position=3)]
        [string]$ArchiveFileName = ""
    )

    Import-Module "$PSScriptRoot/Helpers.psm1"

    function Get-FileNameFromUrl {
        param($Url)

        try {
            $uri = [System.Uri]$Url
            $fileName = [System.IO.Path]::GetFileName($uri.LocalPath)

            if ([string]::IsNullOrEmpty($fileName) -or $fileName -eq "/") {
                throw "Cannot determine filename from URL. Please provide a filename using the 4th parameter."
            }

            return $fileName
        }
        catch {
            throw "Cannot determine filename from URL '$Url'. Please provide a filename using the 4th parameter."
        }
    }

    New-Item -Path $WorkingDir -ItemType Directory -Force

    Write-Host "Starting file download and execution process..." -ForegroundColor Green

    if ($ArchiveFileName -eq "") {
        try {
            $fileName = Get-FileNameFromUrl -Url $Url
        }
        catch {
            Write-Error $_
            return
        }
    } else {
        $fileName = $ArchiveFileName
    }

    Write-Host "Downloading from: $Url" -ForegroundColor Yellow
    Write-Host "Filename: $fileName" -ForegroundColor Yellow

    $archivePath = Join-Path $WorkingDir $fileName
    $extractDir = Join-Path $WorkingDir "extracted_$(Get-Random)"

    Write-Host "Downloading $fileName..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $Url -OutFile $archivePath
        Write-Host "Downloaded successfully to: $archivePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download: $_"
        return
    }

    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

    Write-Host "Extracting archive..." -ForegroundColor Yellow
    try {
        Export-Archive -ArchivePath $archivePath -ExtractDir $extractDir
    }
    catch {
        Write-Error $_
        Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        return
    }

    $exeFiles = Get-ChildItem -Path $extractDir -Filter $ExePattern -Recurse
    if ($exeFiles.Count -eq 0) {
        Write-Error "No exe file found matching pattern: $ExePattern"
        Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        return
    }

    $exeFile = $exeFiles[0]
    Write-Host "Found executable: $($exeFile.Name)" -ForegroundColor Green

    Write-Host "Running $($exeFile.Name)..." -ForegroundColor Yellow
    try {
        $process = Start-Process -FilePath $exeFile.FullName -Wait -PassThru
        Write-Host "Process completed with exit code: $($process.ExitCode)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to run executable: $_"
    }

    Write-Host "Cleaning up files..." -ForegroundColor Yellow
    Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
    Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Process completed!" -ForegroundColor Green
}

Export-ModuleMember -Function Start-ExeFromUrl
