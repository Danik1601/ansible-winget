#!powershell

param (
    [string]$action,
    [string]$package
)

function Install-Package {
    param (
        [string]$packageName
    )

    Write-Host "Installing package $packageName..."
    winget install --id $packageName --silent
    if ($?) {
        Write-Host "Package $packageName installed successfully."
    } else {
        Write-Host "Failed to install package $packageName."
    }
}

function Uninstall-Package {
    param (
        [string]$packageName
    )

    Write-Host "Uninstalling package $packageName..."
    winget uninstall --id $packageName --silent
    if ($?) {
        Write-Host "Package $packageName uninstalled successfully."
    } else {
        Write-Host "Failed to uninstall package $packageName."
    }
}

if ($action -eq "install") {
    Install-Package -packageName $package
} elseif ($action -eq "uninstall") {
    Uninstall-Package -packageName $package
} else {
    Write-Host "Invalid action. Use 'install' or 'uninstall'."
}
