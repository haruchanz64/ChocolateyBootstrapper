# choco_bootstrapper.ps1

param (
    [string]$PackageFile,
    [switch]$Interactive,
    [switch]$Help,
    [switch]$YesToAll
)

# === Help Function ===
function Show-Help {
    Write-Host @"
Usage: setup.ps1 [-PackageFile path] [-Interactive] [-YesToAll] [-Help]

- If -PackageFile is provided, reads package names from the file.
- If -Interactive is used (or no file is given), prompts for input.
- If -YesToAll is used, all installations are auto-confirmed.

When run with no parameters, a menu will be displayed to choose how to continue.
"@ -ForegroundColor Cyan
}

# === Admin Check ===
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Please right-click the PowerShell icon and select 'Run as Administrator'." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# === Help Display ===
if ($Help) {
    Show-Help
    exit 0
}

# === Menu Function ===
function Show-Menu {
    Clear-Host
    Write-Host "===== Chocolatey Bootstrapper Menu =====" -ForegroundColor Cyan
    Write-Host "1. Load packages from a file"
    Write-Host "2. Enter packages manually"
    Write-Host "3. View help"
    Write-Host "0. Exit"
    Write-Host "========================================"
}

# === Prepare Package List ===
$packages = @()

if (-not $PackageFile -and -not $Interactive -and -not $Help) {
    do {
        Show-Menu
        $choice = Read-Host "Select an option [0-3]"

        switch ($choice) {
            '1' {
                $PackageFile = Read-Host "Enter the full path to the package file"
                if (-not (Test-Path $PackageFile)) {
                    Write-Host "File not found: $PackageFile" -ForegroundColor Red
                    $PackageFile = $null
                    Start-Sleep -Seconds 2
                } else {
                    $packages = Get-Content $PackageFile |
                        ForEach-Object { $_.Trim() } |
                        Where-Object { $_ -and ($_ -notmatch '^\s*#') }

                    if (-not $packages) {
                        Write-Host "No valid packages found in file. Exiting." -ForegroundColor Yellow
                        exit 1
                    }
                    break
                }
            }
            '2' {
                $Interactive = $true
                $inputString = Read-Host "Enter package names (space-separated) or press Enter to cancel"
                $packages = $inputString -split '\s+' | Where-Object { $_ }

                if (-not $packages) {
                    Write-Host "No packages entered. Exiting." -ForegroundColor Yellow
                    exit 1
                }

                break
            }
            '3' {
                Show-Help
                Read-Host "Press Enter to return to the menu"
            }
            '0' {
                Write-Host "Exiting..."
                exit 0
            }
            default {
                Write-Host "Invalid selection. Please choose 0-3." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}
elseif ($Interactive) {
    $inputString = Read-Host "Enter package names (space-separated) or press Enter to cancel"
    $packages = $inputString -split '\s+' | Where-Object { $_ }

    if (-not $packages) {
        Write-Host "No packages entered. Exiting." -ForegroundColor Yellow
        exit 1
    }
}
elseif ($PackageFile) {
    if (-not (Test-Path $PackageFile)) {
        Write-Host "File not found: $PackageFile"
        exit 1
    }

    $packages = Get-Content $PackageFile |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and ($_ -notmatch '^\s*#') }

    if (-not $packages) {
        Write-Host "No valid packages found in the file. Exiting."
        exit 1
    }
}

# === Start Transcript ===
$logRoot = "$PSScriptRoot\logs"
$logFile = "$logRoot\install-log.txt"
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
Start-Transcript -Path "$logRoot\session-transcript.txt" -Append -Force

# === Chocolatey + Internet Check ===
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

if (-not (Test-Connection -ComputerName "community.chocolatey.org" -Count 1 -Quiet)) {
    Write-Host "No internet connection. Please connect and try again." -ForegroundColor Red
    Stop-Transcript
    exit 1
}

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Start-Sleep -Seconds 5
} else {
    Write-Host "Chocolatey already installed."
}

# === Auto Confirm Prompt ===
$autoConfirm = $false
if ($YesToAll) {
    $autoConfirm = $true
} else {
    $response = Read-Host "Automatically confirm all installs with -y? (y/n)"
    if ($response.ToLower() -eq "y") {
        $autoConfirm = $true
    }
}

# === Begin Install Logging ===
"=== Install Log $(Get-Date) ===" | Out-File $logFile

# === Install Loop ===
$installed = choco list --local-only | ForEach-Object { ($_ -split '\|')[0].Trim() }

foreach ($pkg in $packages) {
    $pkg = $pkg.Trim()
    if ($installed -contains $pkg) {
        Write-Host "$pkg already installed. Skipping."
        continue
    }

    Write-Host "Installing $pkg..."
    $args = "install $pkg --no-progress"
    if ($autoConfirm) {
        $args += " -y"
    }

    Invoke-Expression "choco $args"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "$pkg installed successfully"
        "SUCCESS: $pkg" | Out-File $logFile -Append
    } else {
        Write-Host "Failed to install $pkg"
        "FAILED: $pkg" | Out-File $logFile -Append
    }
}

Stop-Transcript
Write-Host "`nDone! Log: $logFile"
