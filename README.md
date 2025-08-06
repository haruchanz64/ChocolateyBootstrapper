# Chocolatey Bootstrapper
![PowerShell](https://img.shields.io/badge/PowerShell-v5%2B-blue.svg)
![Chocolatey](https://img.shields.io/badge/Chocolatey-Automation-brightgreen.svg)
![License](https://img.shields.io/github/license/haruchanz64/chocolateybootstrapper)

A flexible, general-purpose PowerShell script to automate software installation on Windows using Chocolatey.  
Supports both interactive input and predefined package lists for fast setup.

---

## Features

- Install any package from Chocolatey
- Interactive or file-based input via a user-friendly menu
- Skips already-installed packages
- Optional `-y` auto-confirmation for unattended installs
- Per-package and full-session logging
- Automatically installs Chocolatey if not already installed
- Built-in help and usage guidance
- Safe admin check before execution

---

## Usage

### Run the following command in PowerShell (as Administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://raw.githubusercontent.com/haruchanz64/chocolateybootstrapper/refs/heads/main/choco_bootstrapper.ps1 | iex
```

---

## Modes

### Menu-Driven Mode (Recommended)

If you run the script with **no arguments**, you’ll see a menu like this:

```
===== Chocolatey Bootstrapper Menu =====
1. Load packages from a file
2. Enter packages manually
3. View help
0. Exit
========================================
```

This makes it easy to interactively install packages or choose a saved package list.

```powershell
.\choco_bootstrapper.ps1
```

---

### Use a Package List

To run with a predefined package file:

```powershell
.\choco_bootstrapper.ps1 -PackageFile .\your_package_list.txt
```

> Replace `your_package_list.txt` with the full or relative path to your Chocolatey package list.

---

### Manual Package Entry (Direct Interactive Mode)

To directly enter packages without using the menu:

```powershell
.\choco_bootstrapper.ps1 -Interactive
```

---

### Auto-confirm All Installs (`-y`)

To skip prompts and auto-confirm all installs:

```powershell
.\choco_bootstrapper.ps1 -PackageFile .\your_package_list.txt -YesToAll
```

You will also be prompted in the menu to confirm this when using interactive mode.

---

## Package List Format

Your package list should be a `.txt` file containing one Chocolatey package name per line.  
You can add comments using `#`, and blank lines are ignored.

Example `packages.txt`:

```
# Browsers
brave

# Editors
vscode
sublimetext4
```

Find official package names at: https://community.chocolatey.org/packages

---

## Tips: Use Profiles

You can create reusable profiles for different purposes:

```
profiles/
├── web_dev.txt
├── game_dev.txt
├── minimal.txt
```

Run a profile like this:

```powershell
.\choco_bootstrapper.ps1 -PackageFile .\profiles\web_dev.txt -YesToAll
```

---

## Logging

The script creates a `logs/` folder with:

- A full session transcript (`session-transcript.txt`)
- A per-package install summary (`install-log.txt`)

This helps with auditing or troubleshooting.

---

## License

[MIT](./LICENSE)
