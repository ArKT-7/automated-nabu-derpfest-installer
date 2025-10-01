# 🚀 Automated Derpfest Installer for Xiaomi Pad 5 (nabu)

## A simple and efficient script to flash Derpfest ROM on the Xiaomi Pad 5 (nabu) in fastboot mode and same zip can be flash in recovery.
## ROM A16 Latest Fastboot/Recovery Flashable Download: [DerpFest-v16.0-20250916-1327-nabu-Official-Stable_FASTBOOT_RECOVERY](https://drive.google.com/file/d/1bqquZ0pPO9FcquqTgPwBXAVVIKG5FR70/view?usp=sharing)
### 🏆 Original ROM Creator
### This ROM was built by [P.A.N.Z](https://github.com/ppanzenboeck). Special thanks for making this ROM available!
---
### 🛠 Support
### **ROM Support Group**: [Join here on Telegram](https://t.me/+x29bHVZKa9ZhZjBk) for assistance, updates, and community support.
---

## 📂 Folder Structure
### Download all necessary binaries, files and [images](https://github.com/ArKT-7/automated-nabu-derpfest-installer/releases/tag/derpfest-september-25), and organize them as follows:

```plaintext
Derfest-rom.zip

-install_DerpFest_linux.sh
-install_DerpFest_windows.bat
-update_DerpFest_linux.sh
-update_DerpFest_windows.bat

└── images
    ├── boot.img
    ├── dtbo.img
    ├── ksu-n_boot.img
    ├── magisk_boot.img
    ├── userdata.img
    ├── super.img
    ├── vbmeta.img
    ├── vbmeta_system.img
    └── vendor_boot.img

└── META-INF
    ├── autoinstaller.conf         # Configration file for recovery flasher script
    └── com
        ├── arkt 
        │   └── bootctl                # binary for switch slot
        │   ├── busybox                # Multi-tool binary for Linux shell support
		│   └── dmsetup                # unmaps /userdata before formatting
        │   ├── libhidltransport.so    # Shared HIDL communication lib
        │   └── libhwbinder.so         # Shared binder IPC lib
		│   └── make_f2fs              # f2fs format for userdata
		│   └── mke2fs                 # ext4 format for metadata
		│   └── 7zzs                   # for zip64 support 
        └── google
            └── android
                ├── update-binary 
                └── updater-script 

└── bin
    ├── windows
    │   ├── platform-tools (files)
    │   └── log-tool (tee.exe files)
    └── linux
        └── platform-tools (files)

└── ROOT_APK_INSATLL_THIS_ONLY
    ├── KernelSU_Next.apk
    └── Magisk.apk
```

## 🔧 Installation and Usage

### Windows Users:
- Simply run the .bat file for installation or updating:
  ```plaintext
  install_DerpFest_windows.bat   # For first time installation/with data format
  update_DerpFest_windows.bat    # For updating without data format
  ```
  
### Linux Users:
#### 1. Make sure the scripts are executable(If Needed):
   ```bash
   chmod +x install_DerpFest_linux.sh update_DerpFest_linux.sh
   ```
   
#### 2. Run the installation or update script:
   ```bash
   bash ./install_DerpFest_linux.sh    # For first time installation/with data format
   bash ./update_DerpFest_linux.sh     # For updating without data format
   ```

### 📜 Notes
- **Images Folder:** Contains necessary partition images.
- **ROOT_APK_INSATLL_THIS_ONLY Folder:** Stores **[Magisk apk](https://github.com/topjohnwu/Magisk/releases/tag/v29.0)** from which the Magisk boot is patched and **[KernelSU NEXT apk](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v1.0.8)** (For root).
- **Bin Folder:** Stores platform tools and logging utilities for both Windows and Linux.
  - **Platform Tools for Windows:** **[Download here](https://dl.google.com/android/repository/platform-tools-latest-windows.zip)**  
  - **Platform Tools for Linux:** **[Download here](https://dl.google.com/android/repository/platform-tools-latest-linux.zip)**  
  - **tee.exe for Windows logging utility:** **[Download here](https://github.com/dEajL3kA/tee-win32)**
  - If these files or folders are missing, the script will automatically download the required files, create the necessary folders, and place the platform tools and logging utilities in the appropriate locations.


---
### Enjoy a smooth flashing experience with the **Automated Derpfest Installer**!
---

