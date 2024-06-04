#!powershell

# Имя модуля: winget.ps1
# Этот модуль управляет приложениями через Winget на Windows-хосте

param (
    [string]$action,
    [string]$package
)

# Функция для проверки наличия приложения через Winget
function Check_If_Installed {
    param (
        [string]$packageID
    )

    Write-Host "Checking $packageID..."
    $InstalledApps = winget list
    return $InstalledApps -match $packageID
}

# Функция для проверки наличия обновления через Winget
function Check_If_Updatable {
    param (
        [string]$packageID
    )

    Write-Host "Checking $packageID..."
    return [int] (winget list --id $packageID | Select-String '\bVersion\s+Available\b' -Quiet)
}

# Функция для установки приложения через Winget
function Install-Package {
    param (
        [string]$packageID
    )

    Write-Host "Installing package $packageID..."
    if (-not (Check_If_Installed -packageID $packageID)) {
        winget install --id $packageID --silent --no-upgrade
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Package $packageID installed successfully."
        } elseif ($LASTEXITCODE -eq -1978335135) {
            Write-Output "Already installed."
        } elseif ($LASTEXITCODE -eq -1978335189) {
            Write-Output "Already installed and upgraded."
        } else {
            Write-Host "Failed to install package $packageID."
        }
    }
    else {
        Write-Host "Package $packageID is already Installed."
    }
}

# Функция для удаления приложения через Winget
function Uninstall-Package {
    param (
        [string]$packageID
    )

    Write-Host "Uninstalling package $packageID..."
    if (Check_If_Installed -packageID $packageID) {
        winget uninstall --id $packageID --silent
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Package $packageID uninstalled successfully."
        } elseif ($LASTEXITCODE -eq -1978335212) {
            Write-Output "Already uninstalled."
        } else {
            Write-Host "Failed to uninstall package $packageID."
        }
    }
    else {
        Write-Host "Package $packageID is already Uninstalled."
    }
}

# Функция для обновления приложения через Winget
function Update-Package {
    param (
        [string]$packageID
    )

    Write-Host "Updating package $packageID..."
    if (Check_If_Updatable -packageID $packageID) {
        winget update --id $packageID --silent
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Package $packageID updated successfully."
        } elseif ($LASTEXITCODE -eq -1978335189) {
            Write-Output "Already updated."
        } elseif ($LASTEXITCODE -eq -1978335212) {
            Write-Output "This package is not installed."
        } else {
            Write-Host "Failed to update package $packageID."
        }
    }
    else {
        Write-Host "Package $packageID is already updated."
    }
}



# Запуск функций в сответствии с переданными параметрами
if ($action -eq "install") {
    Install-Package -packageID $package
} elseif ($action -eq "uninstall") {
    Uninstall-Package -packageID $package
} elseif ($action -eq "update") {
    Update-Package -packageID $package
} else {
    Write-Host "Invalid action. Use 'install', 'uninstall' or 'update'."
}
