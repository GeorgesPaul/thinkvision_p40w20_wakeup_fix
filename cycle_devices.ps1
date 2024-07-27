# Set the sleep time variable at the top of the script
$sleepTime = 0

# Check for administrative privileges
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# If not running as admin, relaunch as admin
if (-not (Test-Admin)) {
    Write-Host "This script requires administrative privileges. Please run PowerShell as an administrator and try again."
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

function Cycle-Device {
    param (
        [string]$deviceId,
        [switch]$force = $false
    )
    
    $device = Get-PnpDevice -InstanceId $deviceId -ErrorAction SilentlyContinue
    
    if ($device) {
        Write-Host "Attempting to cycle device: $($device.FriendlyName)"
        try {
            Write-Host "  Disabling device..."
            if ($force) {
                $null = & "$env:SystemRoot\System32\pnputil.exe" /disable-device $deviceId
            } else {
                Disable-PnpDevice -InstanceId $deviceId -Confirm:$false
            }
            Start-Sleep -Seconds $sleepTime
            Write-Host "  Enabling device..."
            Enable-PnpDevice -InstanceId $deviceId -Confirm:$false
            Write-Host "  Device cycled successfully."
        } catch {
            Write-Host "  Error cycling device: $_"
            Write-Host "  Current device status: $($device.Status)"
        }
    } else {
        Write-Host "Device not found: $deviceId"
    }
}

# Main script starts here
try {
    # Specific device (likely your external monitor's USB hub)
    $specificDeviceId = "USB\VID_17EF&PID_1043\B&31DBCFEA&0&2"

    # Cycle the specific device
    Write-Host "Cycling the specific device (likely external monitor's USB hub)..."
    Cycle-Device $specificDeviceId -force

    # Cycle all Generic USB Hubs
    Write-Host "Cycling all Generic USB Hubs..."
    $genericUsbHubs = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Generic*USB Hub*" -and $_.Status -eq "OK" }
    foreach ($hub in $genericUsbHubs) {
        Cycle-Device $hub.InstanceId -force
    }

    # # Cycle specific Ethernet device (Realtek USB GbE Family Controller)
    # # This is not needed as cycling the USB hubs takes care of cycling the Ethernet adapter as well
    # Write-Host "Cycling Realtek USB GbE Family Controller..."
    # $realtekDevice = Get-PnpDevice | Where-Object { $_.FriendlyName -eq "Realtek USB GbE Family Controller" }
    # if ($realtekDevice) {
    #     Cycle-Device $realtekDevice.InstanceId -force
    # } else {
    #     Write-Host "Realtek USB GbE Family Controller not found."
    # }

    Write-Host "Device cycling completed."
} catch {
    Write-Host "An error occurred during script execution: $_"
} finally {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}