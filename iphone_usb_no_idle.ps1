# Stop Windows from idling or powering down an iPhone during USB photo transfer.
#
# Run once per machine, after the iPhone has been plugged in at least once
# (Windows creates the device entries on first connect):
#
#   powershell -ExecutionPolicy Bypass -File iphone_usb_no_idle.ps1
#
# It asks for administrator rights, then:
#   1. turns off USB selective suspend on the active power plan (AC and battery);
#   2. turns off the idle flags on every Apple USB device entry;
#   3. turns off "Allow the computer to turn off this device" on all USB root hubs.
# Replug the phone afterwards. A new USB port creates a new device entry with
# the defaults, so run it again after the phone has been seen on that port.

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', "`"$PSCommandPath`""
    return
}

$usbSubgroup = '2a737441-1930-4402-8d77-b2bebba308a3'
$selectiveSuspend = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'
powercfg /setacvalueindex SCHEME_CURRENT $usbSubgroup $selectiveSuspend 0
powercfg /setdcvalueindex SCHEME_CURRENT $usbSubgroup $selectiveSuspend 0
powercfg /setactive SCHEME_CURRENT
'OK  USB selective suspend off on the active power plan'

$nodes = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\USB' |
    Where-Object { $_.PSChildName -match '^VID_05AC' } |
    ForEach-Object { Get-ChildItem $_.PSPath }
if (-not $nodes) {
    'No Apple USB device entries found. Plug the iPhone in once, tap Trust, then run this again.'
}
foreach ($node in $nodes) {
    $params = Join-Path $node.PSPath 'Device Parameters'
    if (-not (Test-Path $params)) { continue }
    $name = $node.Name -replace '.*\\Enum\\', ''
    try {
        foreach ($value in 'DeviceIdleEnabled', 'UserSetDeviceIdleEnabled', 'DefaultIdleState') {
            Set-ItemProperty -Path $params -Name $value -Value 0 -Type DWord -ErrorAction Stop
        }
        "OK  idle off: $name"
    } catch {
        "FAILED  idle off: $name : $($_.Exception.Message)"
    }
}

Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable |
    Where-Object { $_.InstanceName -match 'ROOT_HUB' -and $_.Enable } |
    ForEach-Object {
        $name = $_.InstanceName
        try {
            Set-CimInstance -InputObject $_ -Property @{ Enable = $false } -ErrorAction Stop
            "OK  hub power-down off: $name"
        } catch {
            "FAILED  hub power-down off: $name : $($_.Exception.Message)"
        }
    }

'Done. Unplug the iPhone and plug it back in, unlocked.'
