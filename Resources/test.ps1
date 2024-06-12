#!powershell

# Имя модуля: ansible-winget.ps1
# Этот модуль управляет приложениями через Winget на управляемом Windows-узле

#AnsibleRequires -CSharpUtil Ansible.Basic

param()

$spec = @{
    options = @{
        appID = @{ type = "str"; required = $true }
        state = @{ type = "str"; choices = @("absent", "present", "updated"); required = $true }
        scope = @{ type = "str"; choices = @("user", "machine"); required = $false }
        version = @{ type = "str"; required = $false }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$appID = $module.Params.appID
$state = $module.Params.state
$scope = $module.Params.scope
$version = $module.Params.version

# Функция для получения параметров scope и version
function Get-Params {
    param (
        [string]$scope,
        [string]$version
    )

    $scopeParam = if ($scope) { "--scope $scope" } else { "" }
    $versionParam = if ($version) { "--version $version" } else { "" }
    
    return @{ scopeParam = $scopeParam; versionParam = $versionParam }
}

# Функция для проверки наличия приложения через Winget
function Check_If_Installed {
    param (
        [string]$packageID,
        [string]$scope
    )

    Write-Verbose "Checking $packageID..."
    $params = Get-Params -scope $scope
    $output = winget list $packageID $params.scopeParam
    return $?
}

# Функция для проверки наличия обновления через Winget
function Check_If_Updatable {
    param (
        [string]$packageID,
        [string]$scope
    )

    Write-Verbose "Checking $packageID..."
    $params = Get-Params -scope $scope
    return [int64] (winget list --id $packageID $params.scopeParam | Select-String '\bVersion\s+Available\b' -Quiet)
}

# Функция для установки приложения через Winget
function Install-Package {
    param (
        [string]$packageID,
        [string]$scope,
        [string]$version
    )

    Write-Verbose "Installing package $packageID..."
    if (-not (Check_If_Installed -packageID $appID -scope $scope)) {
        $params = Get-Params -scope $scope -version $version
        $output = winget install --id $packageID --silent --no-upgrade $params.scopeParam $params.versionParam
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
        Write-Verbose "Package $packageID is already installed."
    }
}

# Функция для удаления приложения через Winget
function Uninstall-Package {
    param (
        [string]$packageID,
        [string]$scope
    )

    Write-Verbose "Uninstalling package $packageID..."
    if (Check_If_Installed -packageID $appID -scope $scope) {
        $params = Get-Params -scope $scope
        $output = winget uninstall --id $packageID --silent $params.scopeParam
        if ($?) {
            Write-Verbose "Package $packageID uninstalled successfully."
        } elseif ($LASTEXITCODE -eq -1978335212) {
            Write-Verbose "Already uninstalled."
        } else {
            Write-Verbose "Failed to uninstall package $packageID."
        }
    }
    else {
        Write-Verbose "Package $packageID is already uninstalled."
    }
}

# Функция для обновления приложения через Winget
function Update-Package {
    param (
        [string]$packageID,
        [string]$scope
    )
    
    Write-Verbose "Updating package $packageID..."
    if (Check_If_Updatable -packageID $appID -scope $scope) {
        $params = Get-Params -scope $scope
        $output = winget update --id $packageID --silent $params.scopeParam
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

# Запуск функций в соответствии с переданными параметрами
if ($state -eq "present") {
    Install-Package -packageID $appID -scope $scope -version $version
} elseif ($state -eq "absent") {
    Uninstall-Package -packageID $appID -scope $scope
} elseif ($state -eq "updated") {
    Update-Package -packageID $appID -scope $scope
} else {
    Write-Host "Invalid state. Use 'present', 'absent' or 'updated'."
}

$module.ExitJson()
