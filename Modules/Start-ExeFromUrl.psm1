# Enhanced Archive Downloader and Runner
# Downloads an archive OR exe from a URL, extracts if needed, runs the exe, then cleans up
#
# Usage:
#   Start-ExeFromUrl <url> [filename] [working_dir]
#
# Examples:
#   Start-ExeFromUrl "https://example.com/myapp.zip"
#   Start-ExeFromUrl "https://example.com/app.exe"
#   Start-ExeFromUrl (Get-LatestGitHubRelease "zk-org/zk" "*windows-x86_64.tar.gz")
#   Start-ExeFromUrl "https://example.com/app.tar.gz" "custom.tar.gz"
#   Start-ExeFromUrl "https://example.com/standalone.exe" "" "C:\temp"
#   Start-ExeFromUrl "https://example.com/download?id=123" "custom.zip" "C:\temp"

function Start-ExeFromUrl {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Url,

        [Parameter(Position=1)]
        [string]$FileName = "",

        [Parameter(Position=2)]
        [string]$WorkingDir = "$env:TEMP/StartExeFromUrl/"
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

    function Test-IsArchive {
        param($FilePath)

        $archiveExtensions = @('.zip', '.tar', '.gz', '.7z', '.rar', '.tar.gz', '.tar.bz2', '.tar.xz')
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

        # Handle .tar.gz and similar double extensions
        if ($FilePath -match '\.(tar\.(gz|bz2|xz))$') {
            return $true
        }

        return $archiveExtensions -contains $extension
    }

    New-Item -Path $WorkingDir -ItemType Directory -Force

    Write-Host "Starting file download and execution process..." -ForegroundColor Green

    if ($FileName -eq "") {
        try {
            $fileName = Get-FileNameFromUrl -Url $Url
        }
        catch {
            Write-Error $_
            return
        }
    } else {
        $fileName = $FileName
    }

    Write-Host "Downloading from: $Url" -ForegroundColor Yellow
    Write-Host "Filename: $fileName" -ForegroundColor Yellow

    $filePath = Join-Path $WorkingDir $fileName
    $isArchive = Test-IsArchive -FilePath $fileName

    Write-Host "Downloading $fileName..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $Url -OutFile $filePath
        Write-Host "Downloaded successfully to: $filePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download: $_"
        return
    }

    if ($isArchive) {
        Write-Host "File is an archive - extracting..." -ForegroundColor Yellow
        $extractDir = Join-Path $WorkingDir "extracted_$(Get-Random)"
        New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

        try {
            Export-Archive -ArchivePath $filePath -ExtractDir $extractDir
        }
        catch {
            Write-Error $_
            Remove-Item $filePath -Force -ErrorAction SilentlyContinue
            Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
            return
        }

        $exeFiles = Get-ChildItem -Path $extractDir -Filter "*.exe" -Recurse
        if ($exeFiles.Count -eq 0) {
            Write-Error "No exe file found in archive"
            Remove-Item $filePath -Force -ErrorAction SilentlyContinue
            Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
            return
        }

        $exeFile = $exeFiles[0]
        Write-Host "Found executable: $($exeFile.Name)" -ForegroundColor Green
        $executablePath = $exeFile.FullName
        $cleanupPaths = @($filePath, $extractDir)
    } else {
        Write-Host "File is a direct executable" -ForegroundColor Yellow
        $executablePath = $filePath
        $cleanupPaths = @($filePath)
    }

    Write-Host "Running $(Split-Path $executablePath -Leaf)..." -ForegroundColor Yellow
    try {
        $process = Start-Process -FilePath $executablePath -PassThru
        Write-Host "Process Started..." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to run executable: $_"
    }

    Write-Host "When process is completed, come back here and hit enter..." -ForegroundColor Green
    Read-Host

    Write-Host "Cleaning up files..." -ForegroundColor Yellow
    foreach ($path in $cleanupPaths) {
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "Process completed!" -ForegroundColor Green
}

Export-ModuleMember -Function Start-ExeFromUrl
