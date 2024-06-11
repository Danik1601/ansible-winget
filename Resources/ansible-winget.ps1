#!powershell

# Имя модуля: ansible-winget.ps1
# Этот модуль управляет приложениями через Winget на управляемом Windows-узле

#AnsibleRequires -CSharpUtil Ansible.Basic

param()

$spec = @{
    options = @{
        appID = @{ type = "str"; required = $true }
        state = @{ type = "str"; choices = "absent", "present", "updated"; required = $true }
        # scope = @{ type = "str"; default = "user"; choices = "user", "machine" }
        # version = @{ type = "str"}
    }
#    required_one_of = @(, @("appID", "state"))
    supports_check_mode = $true
}

    $module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

    $appID = $module.Params.appID
    $state = $module.Params.state

# Функция для проверки наличия приложения через Winget
function Check-If-Installed {
    param (
        [string]$packageID
    )

    Write-Output "Checking $packageID..."
    $InstalledApps = winget list $packageID
    $InstalledApp = $InstalledApps -match $packageID
    # Write-Output "$?"
    # return $?

    # Если пакет найден, возвращаем True, иначе False
    if ($InstalledApp) {
        return $true
    } else {
        return $false
    }
}

# Функция для проверки наличия обновления через Winget
function Check-If-Updatable {
    param (
        [string]$packageID
    )

    # Write-Output "Checking $packageID..."
    return [int64] (winget list --id $packageID | Select-String '\bVersion\s+Available\b' -Quiet)
}

# Функция для установки приложения через Winget
function Install-Package {
    param (
        [string]$packageID
    )

    # Write-Output "Installing package $packageID..."
    if (Check-If-Installed -packageID $appID) {
        $output = winget install --id $packageID --silent --no-upgrade
        if ($?) {
            Write-Output "Package $packageID installed successfully."
        } elseif ($LASTEXITCODE -eq -1978335135) {
            Write-Output "Already installed."
        } elseif ($LASTEXITCODE -eq -1978335189) {
            Write-Output "Already installed and upgraded."
        } else {
            Write-Output "Failed to install package $packageID."
        }
    }
    else {
        Write-Output "Package $packageID is already Installed."
        # return 0
    }
}

# Функция для удаления приложения через Winget
function Uninstall-Package {
    param (
        [string]$packageID
    )

    # Write-Output "Uninstalling package $packageID..."
    if (-not (Check-If-Installed -packageID $appID)) {
        $output = winget uninstall --id $packageID --silent
        if ($?) {
            Write-Output "Package $packageID uninstalled successfully."
        } elseif ($LASTEXITCODE -eq -1978335212) {
            Write-Output "Already uninstalled."
        } else {
            Write-Output "Failed to uninstall package $packageID."
        }
    }
    else {
        Write-Output "Package $packageID is already Uninstalled."
        # return 0
    }
}

# Функция для обновления приложения через Winget
function Update-Package {
    param (
        [string]$packageID
    )
    
    # Write-Output "Updating package $packageID..."
    if (Check-If-Updatable -packageID $appID) {
        $output = winget update --id $packageID --silent
        if ($?) {
            Write-Output "Package $packageID updated successfully."
        } elseif ($LASTEXITCODE -eq -1978335189) {
            Write-Output "Already updated."
        } elseif ($LASTEXITCODE -eq -1978335212) {
            Write-Output "This package is not installed."
        } else {
            Write-Output "Failed to update package $packageID."
        }
    }
    else {
        Write-Output "Package $packageID is already updated."
        # return 0
    }
}



# Запуск функций в сответствии с переданными параметрами
if ($state -eq "present") {
    Install-Package -packageID $appID
} elseif ($state -eq "absent") {
    Uninstall-Package -packageID $appID
} elseif ($state -eq "updated") {
    Update-Package -packageID $appID
} else {
    Write-Output "Invalid state. Use 'present', 'absent' or 'updated'."
}



$module.ExitJson()