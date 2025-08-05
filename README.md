# Chocolatey Bootstrapper

A flexible, general-purpose PowerShell script to automate software installation on Windows using Chocolatey.  
Supports both interactive input and predefined package lists for fast setup.

---

## Features

- Install any package from Chocolatey
- Interactive or file-based input
- Skips already-installed packages
- Optional `-y` auto-confirmation for unattended installs
- Per-package and full-session logging
- Automatically installs Chocolatey if not already installed

---

## Usage

### Run the following command in PowerShell (as Administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://raw.githubusercontent.com/haruchanz64/chocolatey-bootstrapper/refs/heads/main/choco_bootstrapper.ps1 | iex
```

### Interactive mode (enter packages manually)
```powershell
.\choco_bootstrapper.ps1
```

### Use a package list
```powershell
.\choco_bootstrapper.ps1 -PackageFile .\{your_package_list.txt}
```
> Replace `{your_package_list.txt}` with the full or relative path to your Chocolatey package list.

### Auto-confirm all installs (`-y`)
```powershell
.\choco_bootstrapper.ps1 -PackageFile .\{your_package_list.txt} -YesToAll
```

---

## Package List Format

Your package list should be a `.txt` file containing one Chocolatey package name per line. You can add comments using `#`, and blank lines are ignored.

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

You can create reusable profiles:

```
web_dev.txt
game_dev.txt
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

---

## License

[MIT](./LICENSE)
