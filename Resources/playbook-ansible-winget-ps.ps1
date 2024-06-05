#!powershell

# Имя модуля: winget.ps1
# Этот модуль управляет приложениями через Winget на Windows-хосте

#AnsibleRequires -CSharpUtil Ansible.Basic

param()

$spec = @{
    options = @{
        appID = @{ type = "str" }
        state = @{ type = "str"; choices = "absent", "present", "updated" }
    }
    supports_check_mode = $true
}
  
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
  
$appID = $module.Params.appID
$state = $module.Params.state

# Функция для проверки наличия приложения через Winget
function Check_If_Installed {
    param (
        [string]$packageID
    )

    Write-Output "Checking $packageID..."
    $InstalledApps = winget list
    return $InstalledApps -match $packageID
}

# Функция для проверки наличия обновления через Winget
function Check_If_Updatable {
    param (
        [string]$packageID
    )

    Write-Output "Checking $packageID..."
    return [int64] (winget list --id $packageID | Select-String '\bVersion\s+Available\b' -Quiet)
}

# Функция для установки приложения через Winget
function Install-Package {
    param (
        [string]$packageID
    )

    Write-Output "Installing package $packageID..."
    if (-not (Check_If_Installed -packageID $packageID)) {
        $installResult = winget install --id $packageID --silent --no-upgrade 2>&1
        Write-Output $installResult
        return $LASTEXITCODE
    } else {
        Write-Output "Package $packageID is already installed."
        return 0
    }
}

# Функция для удаления приложения через Winget
function Uninstall-Package {
    param (
        [string]$packageID
    )

    Write-Output "Uninstalling package $packageID..."
    if (Check_If_Installed -packageID $packageID) {
        $uninstallResult = winget uninstall --id $packageID --silent 2>&1
        Write-Output $uninstallResult
        return $LASTEXITCODE
    } else {
        Write-Output "Package $packageID is not installed."
        return 0
    }
}

# Функция для обновления приложения через Winget
function Update-Package {
    param (
        [string]$packageID
    )

    Write-Output "Updating package $packageID..."
    if (Check_If_Updatable -packageID $packageID) {
        $updateResult = winget update --id $packageID --silent 2>&1
        Write-Output $updateResult
        return $LASTEXITCODE
    } else {
        Write-Output "Package $packageID is already updated."
        return 0
    }
}

# Запуск функций в сответствии с переданными параметрами
try {
    if ($state -eq "present") {
        $exitCode = Install-Package -packageID $appID
    } elseif ($state -eq "absent") {
        $exitCode = Uninstall-Package -packageID $appID
    } elseif ($state -eq "updated") {
        $exitCode = Update-Package -packageID $appID
    } else {
        Write-Output "Invalid state. Use 'present', 'absent' or 'updated'."
        $exitCode = 1
    }

    $module.ExitJson(@{
        changed = $true
        exit_code = $exitCode
    })
} catch {
    $module.FailJson(@{
        msg = $_.Exception.Message
        exception = $_.Exception
    })
}
