# iPhone USB fix for Windows

Stops a Windows PC from dropping an iPhone partway through a large photo or video transfer over USB.

## The problem

You copy thousands of photos from an iPhone to Windows (File Explorer, the Photos app or another importer). Partway through, the phone disconnects and reconnects, and the copy fails, sometimes with "A device attached to the system is not functioning" or "The device is unreachable".

One cause is Windows power management. During a long copy there are short gaps in USB traffic. Windows treats the iPhone as idle and suspends it, or the USB hub it's on, and the phone sees that as a disconnect.

## What the script changes

[`iphone_usb_no_idle.ps1`](iphone_usb_no_idle.ps1) makes three changes:

1. **USB selective suspend off** on the active power plan, both plugged in and on battery.
2. **Idle flags off** on every Apple USB device entry Windows knows about (Apple's vendor ID is `VID_05AC`). It sets `DeviceIdleEnabled`, `UserSetDeviceIdleEnabled` and `DefaultIdleState` to 0 under `HKLM\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC*\<id>\Device Parameters`. There is no setting for this in the Windows UI.
3. **"Allow the computer to turn off this device to save power" off** on all USB root hubs.

It works with any iPhone or iPad, not only one specific phone. It also touches other Apple USB devices that have been plugged in, such as a wired keyboard, which does no harm.

## Requirements

- Windows 10 or 11, with administrator rights.
- An iPhone or iPad connected with a USB cable.
- Apple's USB drivers ("Apple Mobile Device USB Driver"), without which Windows doesn't see the phone at all. They come with the Apple Devices app or iTunes from the Microsoft Store. If File Explorer already shows the phone, they're installed.

## How to use it

1. Plug the iPhone in, unlock it and tap **Trust**, so Windows creates its device entries.
2. Download `iphone_usb_no_idle.ps1`, read it, then run:
   ```
   powershell -ExecutionPolicy Bypass -File iphone_usb_no_idle.ps1
   ```
   It asks for administrator rights, then prints one `OK` or `FAILED` line for each change.
3. Unplug the iPhone and plug it back in, unlocked.

Run it once per machine. Windows creates a new device entry when the phone appears on a different USB port, and that entry gets the defaults again, so run the script again after using a new port.

## Doing it by hand

- **Selective suspend:** Control Panel → Power Options → Change plan settings → Change advanced power settings → USB settings → USB selective suspend setting → Disabled.
- **Root hubs:** Device Manager → Universal Serial Bus controllers → each "USB Root Hub" → Properties → Power Management → untick "Allow the computer to turn off this device to save power".
- **Apple device idle flags:** in `regedit`, the registry path above.

## Undo

- Set USB selective suspend back to Enabled, and tick the root hub checkbox again.
- For the registry, set the three values to 1, or delete the Apple entries under `Enum\USB\VID_05AC*` in Device Manager by uninstalling the device. Windows recreates them with the defaults on the next connect.

Keeping USB devices powered uses slightly more battery on a laptop.

## If it still disconnects

- On the iPhone, open **Settings → Photos → Transfer to Mac or PC** and choose **Keep Originals**. With "Automatic", the phone converts HEIC/HEVC during the copy, and the conversion is a frequently reported cause of dropouts.
- Keep the phone unlocked during the copy, and use a direct port on the PC rather than a hub.
- Try another cable.

## License

MIT, see [LICENSE](LICENSE).
