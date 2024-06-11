#!powershell

# Имя модуля: ansible-winget.ps1
# Этот модуль управляет приложениями через Winget на управляемом Windows-узле

#AnsibleRequires -CSharpUtil Ansible.Basic

param()

$spec = @{
    options = @{
        appID = @{ type = "str"; required = $true }
        state = @{ type = "str"; choices = "absent", "present", "updated"; required = $true }
        # scope = @{ type = "str"; choices = "user", "machine" }
        # version = @{ type = "str"}
    }
#    required_one_of = @(, @("appID", "state"))
    supports_check_mode = $true
}

    $module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

    $appID = $module.Params.appID
    $state = $module.Params.state
    # $scope = $module.Params.scope
    # $version = $module.Params.version

# Функция для проверки наличия приложения через Winget
function Check-If-Installed {
    param (
        [string]$packageID
    )

    Write-Verbose "Checking $packageID..."
    $output = winget list $packageID
    return $?
}

# Функция для проверки наличия обновления через Winget
function Check-If-Updatable {
    param (
        [string]$packageID
    )

    Write-Verbose "Checking $packageID..."
    return [int64] (winget list --id $packageID | Select-String '\bVersion\s+Available\b' -Quiet)
}

# Функция для установки приложения через Winget
function Install-Package {
    param (
        [string]$packageID
    )

    Write-Verbose "Installing package $packageID..."
    if (-not (Check-If-Installed -packageID $appID)) {
        $output = winget install --id $packageID --silent --no-upgrade
        if ($?) {
            Write-Verbose "Package $packageID installed successfully."
        } elseif ($LASTEXITCODE -eq -1978335135) {
            Write-Verbose "Already installed."
        } elseif ($LASTEXITCODE -eq -1978335189) {
            Write-Verbose "Already installed and upgraded."
        } else {
            Write-Verbose "Failed to install package $packageID."
        }
    }
    else {
        Write-Verbose "Package $packageID is already Installed."
    }
}

# Функция для удаления приложения через Winget
function Uninstall-Package {
    param (
        [string]$packageID
    )

    Write-Verbose "Uninstalling package $packageID..."
    if (Check-If-Installed -packageID $appID) {
        $output = winget uninstall --id $packageID --silent
        if ($?) {
            Write-Verbose "Package $packageID uninstalled successfully."
        } elseif ($LASTEXITCODE -eq -1978335212) {
            Write-Verbose "Already uninstalled."
        } else {
            Write-Verbose "Failed to uninstall package $packageID."
        }
    }
    else {
        Write-Verbose "Package $packageID is already Uninstalled."
    }
}

# Функция для обновления приложения через Winget
function Update-Package {
    param (
        [string]$packageID
    )
    
    Write-Verbose "Updating package $packageID..."
    if (Check-If-Updatable -packageID $appID) {
        $output = winget update --id $packageID --silent
        if ($?) {
            Write-Verbose "Package $packageID updated successfully."
        } elseif ($LASTEXITCODE -eq -1978335189) {
            Write-Verbose "Already updated."
        } elseif ($LASTEXITCODE -eq -1978335212) {
            Write-Verbose "This package is not installed."
        } else {
            Write-Verbose "Failed to update package $packageID."
        }
    }
    else {
        Write-Verbose "Package $packageID is already updated."
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
    Write-Host "Invalid state. Use 'present', 'absent' or 'updated'."
}



$module.ExitJson()