# PowerShell

# Имя модуля: winget.ps1
# Этот модуль управляет приложениями через Winget на Windows-хосте

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell Ansible.ModuleUtils.AddType
#Requires -Module Ansible.ModuleUtils.ArgvParser
#Requires -Module Ansible.ModuleUtils.CommandUtil

param()

$spec = @{
    options = @{
        appID = @{ type = "str" }
        state = @{ type = "str"; choices = "absent", "present", "updated" }
    }
    # required_one_of = @(, @("appID", "state"))
    # supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$appID = $module.Params.appID
$state = $module.Params.state

# Define custom exit codes
$EXIT_CODE_SUCCESS = 0
$EXIT_CODE_ALREADY_PRESENT = 1
$EXIT_CODE_ALREADY_ABSENT = 2
$EXIT_CODE_INSTALL_FAILED = 10
$EXIT_CODE_UNINSTALL_FAILED = 20
$EXIT_CODE_UPDATE_FAILED = 30
$EXIT_CODE_INVALID_STATE = 40

# Функция для проверки наличия приложения через Winget
function Check_If_Installed {
    param (
        [string]$packageID
    )

    $InstalledApps = winget list
    return $InstalledApps -match $packageID
}

# Функция для проверки наличия обновления через Winget
function Check_If_Updatable {
    param (
        [string]$packageID
    )

    return [int64] (winget list --id $packageID | Select-String '\bVersion\s+Available\b' -Quiet)
}

# Функция для установки приложения через Winget
function Install-Package {
    param (
        [string]$packageID
    )

    if (-not (Check_If_Installed -packageID $packageID)) {
        winget install --id $packageID --silent --no-upgrade
        if ($LASTEXITCODE -eq 0) {
            return $EXIT_CODE_SUCCESS
        } elseif ($LASTEXITCODE -eq -1978335135) {
            return $EXIT_CODE_ALREADY_PRESENT
        } else {
            return $EXIT_CODE_INSTALL_FAILED
        }
    }
    else {
        return $EXIT_CODE_ALREADY_PRESENT
    }
}

# Функция для удаления приложения через Winget
function Uninstall-Package {
    param (
        [string]$packageID
    )

    if (Check_If_Installed -packageID $packageID) {
        winget uninstall --id $packageID --silent
        if ($LASTEXITCODE -eq 0) {
            return $EXIT_CODE_SUCCESS
        } elseif ($LASTEXITCODE -eq -1978335212) {
            return $EXIT_CODE_ALREADY_ABSENT
        } else {
            return $EXIT_CODE_UNINSTALL_FAILED
        }
    }
    else {
        return $EXIT_CODE_ALREADY_ABSENT
    }
}

# Функция для обновления приложения через Winget
function Update-Package {
    param (
        [string]$packageID
    )

    if (Check_If_Updatable -packageID $packageID) {
        winget update --id $packageID --silent
        if ($LASTEXITCODE -eq 0) {
            return $EXIT_CODE_SUCCESS
        } elseif ($LASTEXITCODE -eq -1978335189) {
            return $EXIT_CODE_SUCCESS
        } elseif ($LASTEXITCODE -eq -1978335212) {
            return $EXIT_CODE_ALREADY_ABSENT
        } else {
            return $EXIT_CODE_UPDATE_FAILED
        }
    }
    else {
        return $EXIT_CODE_SUCCESS
    }
}

# Запуск функций в сответствии с переданными параметрами
if ($state -eq "present") {
    $exitCode = Install-Package -packageID $appID
} elseif ($state -eq "absent") {
    $exitCode = Uninstall-Package -packageID $appID
} elseif ($state -eq "updated") {
    $exitCode = Update-Package -packageID $appID
} else {
    Write-Output "Invalid state. Use 'present', 'absent' or 'updated'."
    $exitCode = $EXIT_CODE_INVALID_STATE
}

# Ensure exitCode is a single integer value
$exitCode = [int]$exitCode

$host.SetShouldExit($exitCode)
