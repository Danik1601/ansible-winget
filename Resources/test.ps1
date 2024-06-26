#!powershell

# Имя модуля: ansible-winget.ps1
# Этот модуль управляет приложениями через Winget на управляемом Windows-узле

#AnsibleRequires -CSharpUtil Ansible.Basic

param()

$spec = @{
    options = @{
        appID = @{ type = "str"; required = $true }
        state = @{ type = "str"; choices = "absent", "present", "updated"; required = $true }
        architecture = @{ type ="str"; choices = "x64", "x86", "arm64"; required = $false }
        scope = @{ type = "str"; choices = "user", "machine"; required = $false }
        version = @{ type = "str"; required = $false }
    }
    supports_check_mode = $true
}

    $module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

    $appID = $module.Params.appID
    $state = $module.Params.state
    $architecture =  $module.Params.architecture
    $scope = $module.Params.scope
    $version = $module.Params.version

# Функция для проверки наличия приложения через Winget
function Check_If_Installed {
    param (
        [string]$packageID
    )

    Write-Verbose "Checking $packageID..."
    $command = winget list $packageID
    return $?
}

# Функция для проверки наличия обновления через Winget
function Check_If_Updatable {
    param (
        [string]$packageID
    )

    Write-Verbose "Checking $packageID..."
    return (winget list --id $packageID | Select-String '\bVersion\s+Available\b' -Quiet)
}

# Функция для формирования команды
function Build_Command {
    param (
        [string]$packageID,
        [string]$state,
        [string]$architecture = $null,
        [string]$scope = $null,
        [string]$version = $null,
        [string]$process = $null
    )

    Write-Verbose "state = $state; process = $process"
    switch ($state) {
    $null {Write-Host "Error. State must not be NULL"}
    present { $process = "install" }
    absent { $process = "uninstall" }
    updated { $process = "update" }
    else { Write-Host "Invalid state. Use 'present', 'absent' or 'updated'." }
    }   

    $execCmd = "winget $process --id $packageID --silent"
    if ($architecture) {
        $execCmd += " --architecture $architecture "
    }
    if ($scope) {
        $execCmd += " --scope $scope"
    }
    if ($version) {
        $execCmd += " --version $version"
    }
    Write-Verbose "Built command: '$execCmd'"
    return $execCmd
}

# Функция для установки приложения через Winget
function Install-Package {
    param (
        [string]$packageID,
        [string]$state,
        [string]$architecture = $null,
        [string]$scope = $null,
        [string]$version = $null
    )

    Write-Verbose "Installing package $packageID..."
    if (-not (Check_If_Installed -packageID $appID)) {
        Write-Verbose "Package $packageID is not installed. Installing now"
        $command = Build_Command -packageID $packageID -state $state -architecture $architecture -scope $scope -version $version
        $output = Invoke-Expression $command
        if ($?) {
            Write-Verbose "Package $packageID installed successfully."
        } elseif ($LASTEXITCODE -eq -1978335135) {
            Write-Verbose "Already installed."
        } elseif ($LASTEXITCODE -eq -1978335189) {
            Write-Verbose "Already installed and upgraded."
        } else {
            Write-Host "Failed to install package $packageID."
        }
    } else {
        Write-Verbose "Package $packageID is already Installed."
    }
}

# Функция для удаления приложения через Winget
function Uninstall-Package {
    param (
        [string]$packageID,
        [string]$state,
        [string]$scope = $null,
        [string]$version = $null
    )

    Write-Verbose "Uninstalling package $packageID..."
    if (Check_If_Installed -packageID $appID) {
        Write-Verbose "Package $packageID is installed. Uninstalling now"
        $command = Build_Command -packageID $packageID -state $state -scope $scope -version $version
        $output = Invoke-Expression $command
        if ($?) {
            Write-Verbose "Package $packageID uninstalled successfully."
        } elseif ($LASTEXITCODE -eq -1978335212) {
            Write-Verbose "Already uninstalled."
        } else {
            Write-Host "Failed to uninstall package $packageID."
        }
    } else {
        Write-Verbose "Package $packageID is already Uninstalled."
    }
}

# Функция для обновления приложения через Winget
function Update-Package {
    param (
        [string]$packageID,
        [string]$state,
        [string]$architecture = $null,
        [string]$scope = $null,
        [string]$version = $null
    )
    
    Write-Verbose "Updating package $packageID..."
    if (Check_If_Updatable -packageID $appID) {
        Write-Verbose "Package $packageID in not updated. Updating now"
        $command = Build_Command -packageID $packageID -state $state -architecture $architecture -scope $scope -version $version
        $output = Invoke-Expression $command
        if ($?) {
            Write-Verbose "Package $packageID updated successfully."
        } elseif ($LASTEXITCODE -eq -1978335189) {
            Write-Verbose "Already updated."
        } elseif ($LASTEXITCODE -eq -1978335212) {
            Write-Verbose "This package is not installed."
        } else {
            Write-Host "Failed to update package $packageID."
        }
    } else {
        Write-Verbose "Package $packageID is already updated."
    }
}

# Запуск функций в соответствии с переданными параметрами
if ($state -eq "present") {
    Install-Package -packageID $appID -state $state -architecture $architecture -scope $scope -version $version
} elseif ($state -eq "absent") {
    Uninstall-Package -packageID $appID -state $state -scope $scope -version $versions
} elseif ($state -eq "updated") {
    Update-Package -packageID $appID -state $state -architecture $architecture -scope $scope -version $version
} else {
    Write-Host "Invalid state. Use 'present', 'absent' or 'updated'."
}

$module.ExitJson()