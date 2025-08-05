# choco_bootstrapper.ps1

param (
    [string]$PackageFile,
    [switch]$Interactive,
    [switch]$Help,
    [switch]$YesToAll
)
# Admin check that works reliably even under 'iex'
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Please right-click the PowerShell icon and select 'Run as Administrator'." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Optional: Start transcript AFTER the admin check
Start-Transcript -Path "C:\logs\session-transcript.txt" -Append -Force

if ($Help) {
    Write-Host @"
Usage: setup.ps1 [-PackageFile path] [-Interactive] [-YesToAll] [-Help]

- If -PackageFile is provided, reads package names from the file.
- If -Interactive is used (or no file is given), prompts for input.
- If -YesToAll is used, all installations are auto-confirmed.
"@
    exit 0
}

# === Chocolatey + Internet Checks ===
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

if (-not (Test-Connection -ComputerName "community.chocolatey.org" -Count 1 -Quiet)) {
    Write-Host "No internet connection. Please connect and try again."
    exit 1
}

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Start-Sleep -Seconds 5
} else {
    Write-Host "Chocolatey already installed."
}

# === Load Packages ===
$packages = @()

if ($PackageFile) {
    if (-not (Test-Path $PackageFile)) {
        Write-Host "File not found: $PackageFile"
        exit 1
    }
    Write-Host "Loading packages from file: $PackageFile"
    $packages = Get-Content $PackageFile |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and ($_ -notmatch '^\s*#') }
}
elseif ($Interactive -or -not $PackageFile) {
    $inputString = Read-Host "Enter package names (space-separated) or press Enter to cancel."
    $packages = $inputString -split '\s+' | Where-Object { $_ }
}

if (-not $packages -or $packages.Count -eq 0) {
    Write-Host "No packages to install. Exiting."
    exit 1
}

# === Ask to auto-confirm installs (only if -YesToAll not set) ===
$autoConfirm = $false
if ($YesToAll) {
    $autoConfirm = $true
} else {
    $response = Read-Host "Automatically confirm all installs with -y? (y/n)"
    if ($response.ToLower() -eq "y") {
        $autoConfirm = $true
    }
}

# === Log Setup ===
$logRoot = "$PSScriptRoot\logs"
$logFile = "$logRoot\install-log.txt"
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
Start-Transcript -Path "$logRoot\session-transcript.txt" -Append
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