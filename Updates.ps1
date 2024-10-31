param (
    [switch]$SetupScheduleTask = $false,
    [string]$ScheduledTime = "18:30",  # Default time set to 6:30 PM
    [switch]$UseChoco = $false  # Default is no
)

# Function to create a new PowerShell script for third-party app updates
function Create-ThirdPartyUpdateScript {
    $scriptContent = @"
# Third party apps updates

`$wingetPath = 'C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe'

# Check if Winget exists
if (Test-Path `$wingetPath) {
    try {
        & `$wingetPath upgrade --all --silent --force --accept-package-agreements --accept-source-agreements
        Write-Host 'Winget upgrade completed successfully.'
    } catch {
        Write-Host 'Error during Winget upgrade: `$_.'
    }
} else {
    Write-Host 'Winget not found at `$wingetPath'
    # Try install via Git
    try {
        Write-Host 'Attempting to install Winget via Git...'
        irm asheroto.com/winget | iex
        Write-Host 'Winget installation initiated.'
    } catch {
        Write-Host 'Error during Winget installation via Git: `$_.'
    }
}

# Run Chocolatey upgrade if specified
if ($UseChoco) {
    try {
        choco upgrade all -y
        Write-Host 'Chocolatey upgrade completed successfully.'
    } catch {
        Write-Host 'Error during Chocolatey upgrade: `$_.'
    }
}
Write-Host 'Complete with no errors (if no errors were reported).'
"@

    # Path where the new script will be saved
    $scriptPath = "$env:TEMP\ThirdPartyUpdateScript.ps1"
    Set-Content -Path $scriptPath -Value $scriptContent -Force

    Write-Host "Third-party update script created at $scriptPath"
    return $scriptPath
}

# Function to create a scheduled task
function Create-ScheduledTask {
    param (
        [string]$TaskTime,
        [string]$ScriptPath
    )


    # Create a time-based trigger
    $trigger = New-ScheduledTaskTrigger -Daily -At "$Scheduletime"

    # Define the action to run the third-party update script
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$ScriptPath`""

    # Register the task
    Register-ScheduledTask -TaskName "ThirdPartyAppUpdateTask" -Trigger $trigger -Action $action -Description "Runs third-party app update script daily" -User "SYSTEM" -RunLevel Highest

    Write-Host "Scheduled task created successfully to run at $TaskTime."
}

# Main logic
if ($SetupScheduleTask) {
    # Create the third-party update script and get the path
    $updateScriptPath = Create-ThirdPartyUpdateScript

    # Set up the scheduled task with the generated script
    Create-ScheduledTask -TaskTime $ScheduledTime -ScriptPath $updateScriptPath
} else {
    # Run the third-party update logic directly
    $wingetPath = "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"

    # Check if Winget exists
    if (Test-Path $wingetPath) {
        try {
            & $wingetPath upgrade --all --silent --force --accept-package-agreements --accept-source-agreements
            Write-Host "Winget upgrade completed successfully."
        } catch {
            Write-Host "Error during Winget upgrade: $_"
        }
    } else {
        Write-Host "Winget not found at $wingetPath"
        # Try install via git
        try {
            Write-Host "Attempting to install Winget via Git..."
            irm asheroto.com/winget | iex
            Write-Host "Winget installation initiated."
        } catch {
            Write-Host "Error during Winget installation via Git: $_"
        }
    }

    # Run Chocolatey upgrade if specified
    if ($UseChoco) {
        try {
            choco upgrade all -y
            Write-Host "Chocolatey upgrade completed successfully."
        } catch {
            Write-Host "Error during Chocolatey upgrade: $_"
        }
    }

    Write-Host "Complete with no errors (if no errors were reported)."
}
