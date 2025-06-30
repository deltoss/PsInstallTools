# Gets the latest download URL from GitHub Releases.
#
# Usage:
#   Get-LatestGitHubRelease <Repository> <AssetPattern>
#
# Examples:
#   $downloadUrl = Get-LatestGitHubRelease "zk-org/zk" "*windows-x86_64.tar.gz"
#   Write-Host $downloadUrl
function Get-LatestGitHubRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Repository,

        [Parameter(Mandatory, Position=1)]
        [string]$AssetPattern
    )

    $apiUrl = "https://api.github.com/repos/$Repository/releases/latest"

    try {
        # Fetch the latest release data
        $release = Invoke-RestMethod -Uri $apiUrl -Method Get

        # Find the asset matching the pattern
        $asset = $release.assets | Where-Object {
            $_.name -like $AssetPattern
        }

        if ($asset) {
            $downloadUrl = $asset.browser_download_url
            Write-Host "Latest release: $($release.tag_name)"
            Write-Host "Download URL: $downloadUrl"

            # Return the URL
            return $downloadUrl
        } else {
            Write-Warning "Asset matching '$AssetPattern' not found in latest release"
        }
    } catch {
        Write-Error "Failed to fetch release info: $($_.Exception.Message)"
    }
}

function Export-Archive {
    param($ArchivePath, $ExtractDir)

    $extension = [System.IO.Path]::GetExtension($ArchivePath).ToLower()
    $fileName = [System.IO.Path]::GetFileName($ArchivePath).ToLower()

    Write-Host "Detected archive type: $extension" -ForegroundColor Yellow

    try {
        if ($extension -eq ".zip") {
            Expand-Archive -Path $ArchivePath -DestinationPath $ExtractDir -Force
        }
        elseif ($extension -eq ".tar" -or $fileName -match "\.tar\.(gz|bz2|xz|lz|lzma|Z)$") {
            if (Get-Command tar -ErrorAction SilentlyContinue) {
                & tar -xf $ArchivePath -C $ExtractDir
            } else {
                if (Get-Command 7z -ErrorAction SilentlyContinue) {
                    & 7z x $ArchivePath -o"$ExtractDir"
                } else {
                    throw "Neither tar.exe nor 7z.exe found for tar extraction"
                }
            }
        }
        elseif ($extension -in @(".7z", ".rar", ".gz", ".bz2", ".xz")) {
            if (Get-Command 7z -ErrorAction SilentlyContinue) {
                & 7z x $ArchivePath -o"$ExtractDir"
            } else {
                throw "7z.exe not found. Please install 7-Zip for extracting $extension files"
            }
        }
        else {
            if (Get-Command 7z -ErrorAction SilentlyContinue) {
                & 7z x $ArchivePath -o"$ExtractDir"
            } else {
                throw "Unsupported archive format: $extension. Please install 7-Zip or use a supported format"
            }
        }

        Write-Host "Extraction completed successfully" -ForegroundColor Green
    }
    catch {
        throw "Failed to extract archive: $_"
    }
}

Export-ModuleMember -Function Export-Archive, Get-LatestGitHubRelease
