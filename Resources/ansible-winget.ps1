#!powershell

# Имя модуля: ansible-winget.ps1
# Этот модуль управляет приложениями с использованием ПО Winget на управляемом Windows-узле

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
    param
    (
        [string]$appID
    )

    Write-Verbose "Checking $appID..."
    $command = winget list $appID
    return $?
}



# Функция для проверки наличия обновления через Winget
function Check_If_Updatable {
    param
    (
        [string]$appID
    )

    Write-Verbose "Checking $appID..."
    return (winget list --id $appID | Select-String '\bVersion\s+Available\b' -Quiet)
}



# Функция для формирования команды
function Build_Command {
    param (
        [string]$appID,
        [string]$state,
        [string]$architecture = $null,
        [string]$scope = $null,
        [string]$version = $null,
        [string]$process = $null
    )

    Write-Verbose "state = $state; process = $process"

    switch ($state)
    {
    $null { Write-Host "Error. State must not be NULL" }
    present { $process = "install" }
    absent { $process = "uninstall" }
    updated { $process = "update" }
    else { Write-Host "Invalid state. Use 'present', 'absent' or 'updated'." }
    }   

    $execution_command = "winget $process --id $appID --silent"
    if ($architecture)
    {
        $execution_command += " --architecture $architecture "
    }
    if ($scope)
    {
        $execution_command += " --scope $scope"
    }
    if ($version)
    {
        $execution_command += " --version $version"
    }

    Write-Verbose "Built command: '$execution_command'"
    return $execution_command
}



# Функция для установки приложения через Winget
function Install-Package {
    param
    (
        [string]$appID,
        [string]$state,
        [string]$architecture = $null,
        [string]$scope = $null,
        [string]$version = $null
    )

    Write-Verbose "Installing package $appID..."

    if (-not (Check_If_Installed -appID $appID))
    {
        Write-Verbose "Package $appID is not installed. Installing now"
        $command = Build_Command -appID $appID -state $state -architecture $architecture -scope $scope -version $version
        $output = Invoke-Expression $command

        if ($?)
        {
            Write-Verbose "Package $appID installed successfully."
        }
        elseif ($LASTEXITCODE -eq -1978335135)
        {
            Write-Verbose "Already installed."
        }
        elseif ($LASTEXITCODE -eq -1978335189)
        {
            Write-Verbose "Already installed and upgraded."
        }
        else
        {
            Write-Host "Failed to install package $appID."
        }
    }
    else
    {
        Write-Verbose "Package $appID is already Installed."
    }
}



# Функция для удаления приложения через Winget
function Uninstall-Package {
    param
    (
        [string]$appID,
        [string]$state,
        [string]$scope = $null,
        [string]$version = $null
    )

    Write-Verbose "Uninstalling package $appID..."
    
    if (Check_If_Installed -appID $appID)
    {
        Write-Verbose "Package $appID is installed. Uninstalling now"
        $command = Build_Command -appID $appID -state $state -scope $scope -version $version
        $output = Invoke-Expression $command

        if ($?)
        {
            Write-Verbose "Package $appID uninstalled successfully."
        }
        elseif
        ($LASTEXITCODE -eq -1978335212) {
            Write-Verbose "Already uninstalled."
        }
        else
        {
            Write-Host "Failed to uninstall package $appID."
        }
    }
    else
    {
        Write-Verbose "Package $appID is already Uninstalled."
    }
}



# Функция для обновления приложения через Winget
function Update-Package {
    param
    (
        [string]$appID,
        [string]$state,
        [string]$architecture = $null,
        [string]$scope = $null,
        [string]$version = $null
    )
    
    Write-Verbose "Updating package $appID..."
    if (Check_If_Updatable -appID $appID)
    {
        Write-Verbose "Package $appID in not updated. Updating now"
        $command = Build_Command -appID $appID -state $state -architecture $architecture -scope $scope -version $version
        $output = Invoke-Expression $command

        if ($?)
        {
            Write-Verbose "Package $appID updated successfully."
        }
        elseif ($LASTEXITCODE -eq -1978335189)
        {
            Write-Verbose "Already updated."
        }
        elseif ($LASTEXITCODE -eq -1978335212)
        {
            Write-Verbose "This package is not installed."
        }
        else
        {
            Write-Host "Failed to update package $appID."
        }
    }
    else
    {
        Write-Verbose "Package $appID is already updated."
    }
}



# Запуск функций в соответствии с переданными параметрами
if ($state -eq "present")
{
    Install-Package -appID $appID -state $state -architecture $architecture -scope $scope -version $version
}
elseif ($state -eq "absent")
{
    Uninstall-Package -appID $appID -state $state -scope $scope -version $versions
}
elseif ($state -eq "updated")
{
    Update-Package -appID $appID -state $state -architecture $architecture -scope $scope -version $version
}
else
{
    Write-Host "Invalid state. Use 'present', 'absent' or 'updated'."
}



$module.ExitJson()