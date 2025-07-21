function Install-FromFolder {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$SourceFolder,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$AppName,

        [Parameter(Position=2)]
        [string]$InstallPath = "$env:LOCALAPPDATA\Programs"
    )

    # Resolve and validate source folder
    $SourceFolder = Resolve-Path $SourceFolder -ErrorAction SilentlyContinue
    if (-not $SourceFolder -or -not (Test-Path $SourceFolder -PathType Container)) {
        Write-Error "Source folder not found or invalid: $SourceFolder"
        return
    }

    Write-Host "Source folder resolved to: $SourceFolder"

    # Check if install path exists, create if needed
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Host "Created install directory: $InstallPath"
    }

    $destinationFolder = Join-Path $InstallPath $AppName

    try {
        Write-Host "Installing $AppName from $SourceFolder to $destinationFolder..."

        # Create destination directory if it doesn't exist
        if (-not (Test-Path $destinationFolder)) {
            New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
            Write-Host "Created directory: $destinationFolder"
        } else {
            Write-Host "Directory already exists: $destinationFolder"
        }

        # Copy entire folder contents
        Copy-Item -Path "$SourceFolder\*" -Destination $destinationFolder -Recurse -Force
        Write-Host "Copied all files from $SourceFolder to $destinationFolder"

        # List what was copied
        $copiedFiles = Get-ChildItem $destinationFolder -File
        Write-Host "Installed files:"
        $copiedFiles | ForEach-Object { Write-Host "  - $($_.Name)" }

        # Add to user PATH
        $currentUserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentUserPath -notlike "*$destinationFolder*") {
            # Update persistent user PATH
            $newUserPath = if ($currentUserPath) { $currentUserPath + ";" + $destinationFolder } else { $destinationFolder }
            [Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")

            # Also update current session PATH so it works immediately
            $currentSessionPath = $env:PATH
            if ($currentSessionPath -notlike "*$destinationFolder*") {
                $env:PATH = $currentSessionPath + ";" + $destinationFolder
            }

            Write-Host "Added $destinationFolder to user PATH (persistent)" -ForegroundColor Green
            Write-Host "PATH updated for current session - executables are ready to use!" -ForegroundColor Green
        } else {
            Write-Host "$destinationFolder is already in user PATH"
        }

        Write-Host "Installation completed successfully!" -ForegroundColor Green

        # Show any EXE files found
        $exeFiles = Get-ChildItem $destinationFolder -Filter "*.exe"
        if ($exeFiles) {
            Write-Host "`nExecutable files installed:"
            $exeFiles | ForEach-Object { 
                Write-Host "  - $($_.Name)" -ForegroundColor Cyan
            }
            Write-Host "`nYou can now run these from any command prompt (after restarting your terminal)."
        }

    } catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        return
    }
}

Export-ModuleMember -Function Install-FromFolder
