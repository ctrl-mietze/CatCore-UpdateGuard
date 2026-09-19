<p align="center">
  <img src="docs/assets/banner.svg" alt="CatCore UpdateGuard" width="100%">
</p>

<p align="center">
  <strong>English</strong> · <a href="README_DE.md">Deutsch</a> · <a href="README_ZH.md">中文</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Android-14–16-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android 14–16">
  <img src="https://img.shields.io/badge/Termux-required-111827?style=for-the-badge&logo=gnubash&logoColor=white" alt="Termux required">
  <img src="https://img.shields.io/badge/Access-Root%20%7C%20ADB%20%7C%20Shizuku-F59E42?style=for-the-badge" alt="Root, ADB or Shizuku">
</p>

<p align="center"><strong>Block unwanted Android update components from Termux using the privilege method you already have: Root, ADB, or Shizuku.</strong></p>

CatCore UpdateGuard is a multilingual Termux toolkit for controlling OTA, Google update and manufacturer update components at the package/component level. It supports **other methods for every privilege: ADB, Shizuku, or Root**—choose whichever is available on your device.

This is especially relevant for modern **temporary-root (TempRoot)** workflows: an unexpected OTA can remove temporary root access or lead to update-related boot/security problems. UpdateGuard helps you prevent accidental updates while you control when and how the device is updated.

> UpdateGuard does not patch `/system`, `/vendor`, boot or `vbmeta`. Android firmware differs between devices, so review the detected packages before applying changes. Blocking updates also means you must install important security updates manually when you are ready.

## Install

1. Install [Termux from its official project](https://github.com/termux/termux-app#installation). Do not mix Termux and plugin packages from different sources.
2. Download [`CCUpdateGuard.sh`](CCUpdateGuard.sh) to your phone's **Download** folder.
3. Open Termux and run:

```bash
pkg update
pkg install bash
termux-setup-storage
cp ~/storage/downloads/CCUpdateGuard.sh ~/
chmod +x ~/CCUpdateGuard.sh
```

## Start with Root

Follow a suitable [Android rooting guide](https://github.com/awesome-android-root/awesome-android-root/blob/main/docs%2Frooting-guides%2Findex.md) for your device. In your Superuser manager (for example Magisk, KernelSU or APatch), grant `su` access to **Termux**.

Trigger the permission request and verify root:

```bash
su -c id
```

Then start UpdateGuard and select **Root / su**:

```bash
bash ~/CCUpdateGuard.sh
```

## Start with ADB

Enable **Developer options** and **Wireless debugging** using the official [Android ADB over Wi-Fi guide](https://developer.android.com/tools/adb#connect-to-a-device-over-wi-fi). Keep the Wireless debugging screen and Termux open in split-screen if possible.

Install ADB in Termux, pair using the pairing address/port shown by Android, then connect using the separate wireless-debugging address/port:

```bash
pkg install android-tools
adb pair IP_ADDRESS:PAIRING_PORT
adb connect IP_ADDRESS:DEBUG_PORT
adb devices
bash ~/CCUpdateGuard.sh
```

Select **ADB** in UpdateGuard. The device must appear as `device` in `adb devices`.

## Start with Shizuku

Install [Shizuku](https://github.com/RikkaApps/Shizuku) and start it by following the official [Shizuku setup guide](https://shizuku.rikka.app/guide/setup/). In Shizuku, open **Use Shizuku in terminal apps**, export the `rish` files for Termux, and allow/activate Termux when Shizuku asks for authorization.

Place `rish` and `rish_shizuku.dex` where Termux can find them (for example `$PREFIX/bin`), then make `rish` executable:

```bash
cp /path/to/exported/rish "$PREFIX/bin/rish"
cp /path/to/exported/rish_shizuku.dex "$PREFIX/bin/rish_shizuku.dex"
chmod +x "$PREFIX/bin/rish"
rish -c id
bash ~/CCUpdateGuard.sh
```

Select **Shizuku / rish** in UpdateGuard.

## Run again later

```bash
bash ~/CCUpdateGuard.sh
```

The interface automatically uses **English, German or Chinese** based on the Android/Termux locale. Saved state is stored in `~/.catcore-updateguard`; reports and logs are written to `Download/CatCore-UpdateGuard` when storage access is available.

### Root-only user update service remover

The final menu option is deliberately marked **[DANGEROUS]**. It lists updater-like system packages and can remove only your selected packages from the **current Android user profile** with `pm uninstall --user`; it never deletes their APKs from the system partition. Before any removal, UpdateGuard requires `Y`, the localized acceptance phrase and a separate red warning acknowledgment. APK copies and a package manifest are saved to `Documents/BackupsOSU/<timestamp>`. **Reverse Select**, **Reverse all** and **Reverse + Hard Broken Checker** reinstall those packages for the original user with `install-existing`.

## Important TempRoot note

- Package disable states can remain active after a reboot or after temporary root is lost.
- A stopped `update_engine` process is only stopped for the current boot.
- Restoring changes later requires an available privilege path again: Root, connected ADB, or working Shizuku.
- Do not delete `~/.catcore-updateguard` while protection is active; it contains the state needed for reversal.

## Disclaimer

Use CatCore UpdateGuard at your own risk. No liability is accepted for failed updates, missing security patches, app/device instability, lost access or other damage. Blocking update components through ADB is generally a comparatively safe and reversible user-level method, but it is not risk-free—and while updates are blocked, important Android security updates will not arrive automatically. Review every selected package and restore protection before intentionally updating.

## Release

Download the current [`v1.0.0 release`](https://github.com/ctrl-mietze/CatCore-UpdateGuard/releases/tag/v1.0.0), including the ready-to-run `CCUpdateGuard.sh` asset and GitHub's automatic source archives. The latest source also remains available directly on the `main` branch.

---

<p align="center">
  <strong>CatCore UpdateGuard</strong><br>
  Choose your privilege. Control your updates.
</p>
