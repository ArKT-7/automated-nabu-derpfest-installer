#!/bin/sh
#
# Copyright (C) 2025-26 https://github.com/ArKT-7/Auto-Installer-Forge
#
# Made For Processing ROMs containing payload.bin, converts them into a ready-to-flash super.img, and generates a fully automated installation package for Fastboot or Recovery, which can later be flashed using my custom flasher scripts.

# Define URLs and target paths for binaries
BASE_URL="https://raw.githubusercontent.com/arkt-7/Auto-Installer-Forge/main"
DERP_BASE_URL="https://raw.githubusercontent.com/arkt-7/automated-nabu-derpfest-installer/main"
URL_BUSYBOX="$BASE_URL/bin/linux_amd64/busybox"
URL_PAYLOAD_DUMPER="$BASE_URL/bin/linux_amd64/payload-dumper-go"
URL_LPMAKE="$BASE_URL/bin/linux_amd64/lpmake"
URL_LPUNPACK="$BASE_URL/bin/linux_amd64/lpunpack"
URL_FIGLET="$BASE_URL/bin/linux_amd64/figlet"
URL_FONT1="$BASE_URL/bin/figlet_fonts/standard.flf"
URL_FONT2="$BASE_URL/bin/figlet_fonts/nancyj.flf"
URL_FONT3="$BASE_URL/bin/figlet_fonts/sblood.flf"

current_dir=$(basename "$PWD")
if [ "$current_dir" = "Auto-Installer-Forge" ]; then
  BIN_DIR="$PWD/bin"
  WORK_DIR="$PWD/out"
  MAGISK_DIR="$BIN_DIR/magisk_patch"
else
  BIN_DIR="$PWD/Auto-Installer-Forge/bin"
  WORK_DIR="$PWD/Auto-Installer-Forge/out"
  MAGISK_DIR="$BIN_DIR/magisk_patch"
fi
mkdir -p "$WORK_DIR" "$MAGISK_DIR"
# echo -e "BIN_DIR=$BIN_DIR"
# echo -e "WORK_DIR=$WORK_DIR"
# echo -e "MAGISK_DIR=$MAGISK_DIR"

log() {
    echo -e -e "\n[$(date +"%H:%M:%S")] $1"
}

# Function to download and set permissions
download_and_set_permissions() {
    local url=$1 dest_file=$2
    log "[INFO] Downloading $(basename "$dest_file")..."
    curl -L -# -o "$dest_file" "$url" || { log "[ERROR] Failed to download $(basename "$dest_file")"; exit 1; }
    chmod +x "$dest_file"
    echo -e "[SUCCESS] $(basename "$dest_file") ready."
}

# Function to download files without setting permissions
download_file() {
    local url=$1 dest_file=$2
    #echo -e "[INFO] Downloading $(basename "$dest_file")..."
    curl -L -# -o "$dest_file" "$url" || { log "[ERROR] Failed to download $(basename "$dest_file")"; }
    echo -e "[SUCCESS] $(basename "$dest_file") downloaded."
}

# Function to extract checksum from file
get_checksum() {
    local filename="$1"
    if [ "$CHECKSUM_AVAILABLE" -eq 0 ]; then
        echo " "
        return
    fi
    grep "^$filename=" "$CHECKSUM_FILE" | cut -d'=' -f2
}


# Function to verify checksum
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"

    if [ "$CHECKSUM_AVAILABLE" -eq 0 ]; then
        #echo -e "[WARNING] Checksum verification skipped for $(basename "$file")."
        return 0
    fi

    if [ -z "$expected_checksum" ]; then
        echo -e "[WARNING] No checksum found for $(basename "$file"), skipping verification."
        return 0  # Skip verification if no checksum is available
    fi

    local actual_checksum
    actual_checksum=$($BIN_DIR/busybox sha256sum "$file" | awk '{print $1}')

    if [ "$actual_checksum" = "$expected_checksum" ]; then
        #echo -e "[SUCCESS] Checksum verified for $(basename "$file")."
        return 0
    else
        echo -e "\n[ERROR] Checksum mismatch for $(basename "$file")! Expected: $expected_checksum, Got: $actual_checksum"
        return 1
    fi
}

# Function to attempt download with checksum validation
download_with_fallback() {
    PRIMARY_URL="$1"
    FALLBACK_URL="$2"
    DEST_FILE="$3"
    FILE_KEY="$4"  # Key name in checksum file

    #echo -e "[INFO] Downloading: $(basename "$DEST_FILE")"

    EXPECTED_CHECKSUM=$(get_checksum "$FILE_KEY")

    if download_file "$PRIMARY_URL" "$DEST_FILE"; then
        if verify_checksum "$DEST_FILE" "$EXPECTED_CHECKSUM"; then
            return 0  # Download successful with valid checksum
        else
            echo -e "[WARNING] Checksum mismatch, trying fallback...\n"
            rm -f "$DEST_FILE"
        fi
    else
        echo -e "[WARNING] Primary download failed, trying fallback...\n"
    fi

    # Try downloading from fallback source
    if download_file "$FALLBACK_URL" "$DEST_FILE"; then
        if verify_checksum "$DEST_FILE" "$EXPECTED_CHECKSUM"; then
            return 0  # Fallback successful with valid checksum
        else
            echo -e "[ERROR] Fallback checksum mismatch! Continuing with warning...\n"
            return 1
        fi
    else
        echo -e "[ERROR] Failed to download $(basename "$DEST_FILE") from both sources! Continuing..."
        return 1
    fi
}

process_custom_root() {
    local CUSTOM_ZIP="$1"
    log "[INFO] Processing Custom Root Zip: $CUSTOM_ZIP"
    local C_ROOT_WORK="$TARGET_DIR/custom_root_work"
    local MAGISK_BIN="$MAGISK_DIR/assets/magiskboot"
    local BOOT_IMG="$TARGET_DIR/images/boot.img"

    if [ ! -f "$MAGISK_BIN" ]; then
        log "[ERROR] magiskboot binary not found! Magisk extraction must run first."
        return 1
    fi

    $BIN_DIR/busybox mkdir -p "$C_ROOT_WORK"
    log "[INFO] Extracting 'Image' (Kernel) from custom zip..."
    $BIN_DIR/busybox unzip -q "$CUSTOM_ZIP" -d "$C_ROOT_WORK/extracted_zip"
    local KERNEL_FILE=$(find "$C_ROOT_WORK/extracted_zip" -type f -name "Image" | head -n 1)

    if [ -z "$KERNEL_FILE" ]; then
        log "[ERROR] No file named 'Image' found inside the provided zip!"
        $BIN_DIR/busybox rm -rf "$C_ROOT_WORK"
        return 1
    fi

    log "[INFO] Found kernel image at: $KERNEL_FILE"
    $BIN_DIR/busybox cp "$KERNEL_FILE" "$C_ROOT_WORK/kernel"
    log "[INFO] Copying boot.img for patching..."
    $BIN_DIR/busybox cp "$BOOT_IMG" "$C_ROOT_WORK/boot.img"
    local PREV_DIR="$PWD"
    cd "$C_ROOT_WORK" || return

    log "[INFO] Unpacking boot.img..."
    "$MAGISK_BIN" unpack boot.img > /dev/null 2>&1
    
    if [ ! -f "kernel" ]; then
         log "[ERROR] Failed to unpack boot.img (kernel file missing)."
         cd "$PREV_DIR"
         return 1
    fi

    log "[INFO] Replacing stock kernel with custom kernel..."
    $BIN_DIR/busybox cp "$KERNEL_FILE" "kernel_custom"
    $BIN_DIR/busybox mv -f "kernel_custom" "kernel"
    log "[INFO] Repacking boot.img..."
    "$MAGISK_BIN" repack boot.img > /dev/null 2>&1

    if [ -f "new-boot.img" ]; then
        $BIN_DIR/busybox mv "new-boot.img" "$TARGET_DIR/images/ksu-n_boot.img"
        log "[SUCCESS] Custom Kernel Repack Successful! Saved as: images/ksu-n_boot.img"
    else
        log "[ERROR] Failed to repack boot image with custom kernel."
    fi

    cd "$PREV_DIR"
    $BIN_DIR/busybox rm -rf "$C_ROOT_WORK"
}

# Function to patch boot.img with magisk
patch_magisk_boot() {
    log "[INFO] Patching boot.img with Magisk..\n"

    # Unzip only assets and lib folders; if unzip fails, exit
    if ! $BIN_DIR/busybox unzip -q -o "$TARGET_DIR/ROOT_APK_INSATLL_THIS_ONLY/$1" "assets/*" "lib/*" -d "$MAGISK_DIR"; then
        log "[ERROR] Failed to unzip Magisk APK"
        return 1
    fi

    ARCH_DIR="arm64-v8a"
    LIB_PATH="$MAGISK_DIR/lib/$ARCH_DIR"
    if [ -d "$LIB_PATH" ]; then
        for file in "$LIB_PATH"/*.so; do
            [ -f "$file" ] || continue
            new_name=$(basename "$file" | $BIN_DIR/busybox sed -E 's/^lib(.*)\.so$/\1/')
            mv "$file" "$MAGISK_DIR/assets/$new_name"
        done
    else
        log "[ERROR] Library folder not found for $ARCH_DIR"
        return 1
    fi
    ARCH_DIR="x86_64"
    LIB_PATH="$MAGISK_DIR/lib/$ARCH_DIR"
    if [ -d "$LIB_PATH" ]; then
        for file in "$LIB_PATH"/lib{magiskboot,busybox}.so; do
            [ -f "$file" ] || continue
            new_name=$(basename "$file" | $BIN_DIR/busybox sed -E 's/^lib(.*)\.so$/\1/')
            mv "$file" "$MAGISK_DIR/assets/$new_name"
        done
    else
        log "[ERROR] Library folder not found for $ARCH_DIR"
        return 1
    fi
    chmod -R +x "$MAGISK_DIR/assets/"

    # Extract API version
    sdk_version=$(strings "$TARGET_DIR/images/super.img" | grep -m 1 'ro.build.version.sdk=' | cut -d'=' -f2)
    if [ -z "$sdk_version" ]; then
    sdk_version=36
    fi
    echo -e "API level is: $sdk_version"
    # Extract ABI version
    # abi_version=$(strings "$TARGET_DIR/images/super.img" | grep -m 1 'ro.product.cpu.abi=' | cut -d'=' -f2)
    # if [ -z "$abi_version" ]; then
    abi_version=arm64-v8a
    # fi
    # echo -e "API level is: $abi_version"

    $BIN_DIR/busybox sed -i \
    -e "s|API=\$(grep_get_prop ro.build.version.sdk)|API=$sdk_version|" \
    -e "s|ABI=\$(grep_get_prop ro.product.cpu.abi)|ABI=$abi_version|" \
    "$MAGISK_DIR/assets/util_functions.sh"

    $BIN_DIR/busybox sed -i 's|echo -e "ui_print \$1\\nui_print" >> /proc/self/fd/\$OUTFD|echo -e "\$1"|' "$MAGISK_DIR/assets/util_functions.sh"
    $BIN_DIR/busybox sed -i '1 s|^.*$|#!/bin/bash|' "$MAGISK_DIR/assets/boot_patch.sh"
    $BIN_DIR/busybox sed -i 's/ui_print/echo -e/g' "$MAGISK_DIR/assets/boot_patch.sh"
    # Modify boot_patch.sh to hardcode "sda19" for NABU
    if ! $BIN_DIR/busybox sed -i 's/\$BOOTMODE && \[ -z "\$PREINITDEVICE" \] && PREINITDEVICE=\$(\.\/magisk --preinit-device)/PREINITDEVICE="sda19"/' "$MAGISK_DIR/assets/boot_patch.sh"; then
        log "[ERROR] Failed to modify boot_patch.sh"
        return 1
    fi

    "$MAGISK_DIR/assets/boot_patch.sh" "$TARGET_DIR/images/boot.img"

    if [ -f "$MAGISK_DIR/assets/new-boot.img" ]; then
        $BIN_DIR/busybox cp "$MAGISK_DIR/assets/new-boot.img" "$TARGET_DIR/images/magisk_boot.img"
        log "[SUCCESS] Patching successful! Magisk boot image saved at: $TARGET_DIR/images/magisk_boot.img"
    else
        log "[ERROR] Patching unsuccessful. Please patch manually and add to /images folder..."
        return 1
    fi
    return 0
}

# Function to prompt and update a single config field
update_field() {
    field="$1"
    label="$2"
    direct_value="$3"

    line=$(grep "^$field=" "$CONF_FILE")

    value=$(echo "$line" | $BIN_DIR/busybox sed -n "s/^$field=\"\([^\"]*\)\".*/\1/p")

    comment=$(echo "$line" | $BIN_DIR/busybox sed -n "s/^$field=\"[^\"]*\"[[:space:]]*\(.*\)/\1/p")

    if [ -n "$direct_value" ]; then
        new_value="$direct_value"
    else
        echo -e "Current $label: $value"
        echo -n "Enter new $label (leave blank to keep current): "
        read new_value
        [ -z "$new_value" ] && new_value="$value"
    fi

    escaped_new_value=$(printf '%s\n' "$new_value" | $BIN_DIR/busybox sed 's/[&/\]/\\&/g')

    new_line="$field=\"${escaped_new_value}\""
    [ -n "$comment" ] && new_line="$new_line $comment"

    $BIN_DIR/busybox sed -i "s|^$field=.*|$new_line|" "$CONF_FILE"

    echo -e "$label updated to: $new_value\n"
}

# Start payload zip selector
get_payload_zip_path() {
    local INPUT_PATH="$1"
    INPUT_PATH=$(realpath "$INPUT_PATH" 2>/dev/null)

    if [ -z "$INPUT_PATH" ] || [ ! -e "$INPUT_PATH" ]; then
        echo -e "\nPlease enter the full path to an AOSP ROM ZIP file or a folder containing multiple ROM ZIPs:\n"
        read -r INPUT_PATH
        echo " "
    fi

    #INPUT_PATH=$(echo "$INPUT_PATH" | sed 's:^~:'"$HOME"':' | sed 's:/*$::')

    [ -z "$INPUT_PATH" ] && {
        log "[INFO] No input provided. Exiting...\n"
        exit 1
    }

    candidate_zips=()
    count=0

    if [ -d "$INPUT_PATH" ]; then
        log "[INFO] Searching for payload-containing ZIP files in the specified folder..."
        for zip in $(find "$INPUT_PATH" -type f -name "*.zip"); do
            if $BIN_DIR/busybox unzip -l "$zip" | $BIN_DIR/busybox grep -q "payload.bin"; then
                candidate_zips[count]="$zip"
                count=$((count + 1))
            fi
        done

    elif [ -f "$INPUT_PATH" ]; then
        case "$INPUT_PATH" in
            *.zip)
                log "[INFO] Checking the specified ZIP file for payload.bin..."
                if $BIN_DIR/busybox unzip -l "$INPUT_PATH" | $BIN_DIR/busybox grep -q "payload.bin"; then
                    candidate_zips[0]="$INPUT_PATH"
                    count=1
                fi
                ;;
            *)
                log "[ERROR] The specified file is not a .zip file. Please provide a valid ZIP archive."
                return 1
                ;;
        esac
    else
        log "[ERROR] The specified path is invalid. Please try again."
        return 1
    fi

    if [ "$count" -eq 0 ]; then
        log "[ERROR] No valid ZIP files containing payload.bin were found."
        return 1

    elif [ "$count" -eq 1 ]; then
        log "[SUCCESS] Matching ZIP file found."
        SELECTED_ZIP_FILE="${candidate_zips[0]}"
        return 0
    else
        echo -e "\n[INFO] Multiple ZIP files containing payload.bin were found:\n"
        for i in $(seq 0 $((count - 1))); do
            index=$((i + 1))
            echo -e "$index) ${candidate_zips[$i]}"
        done

        valid=0
        while [ "$valid" -eq 0 ]; do
            echo -e "\nPlease enter the number corresponding to the ZIP file to use (1 - $count): "
            read -r selection
            if echo "$selection" | grep -qE '^[0-9]+$'; then
                index=$((selection - 1))
                if [ "$index" -ge 0 ] && [ "$index" -lt "$count" ]; then
                    SELECTED_ZIP_FILE="${candidate_zips[$index]}"
                    valid=1
                else
                    echo -e "[ERROR] Invalid selection. Please enter a valid number between 1 and $count."
                fi
            else
                echo -e "[ERROR] Invalid selection. Please enter a valid number between 1 and $count."
            fi
        done
    fi
    return 0
}


echo -e "\nAutomating ROM conversion for easy Fastboot/Recovery flashing for Xiaomi Pad 5 (more devices planned)\n"
echo -e "This script is Written and Made By °⊥⋊ɹ∀°, Telegram - '@ArKT_7', Github - 'ArKT-7'\n"

AVAILABLE_SPACE=$(df "$WORK_DIR" | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -lt 15000000 ]; then
    log "[ERROR] Not enough space. Need at least 15GB free!"
    exit 1
fi

# Download required binaries
download_and_set_permissions "$URL_BUSYBOX" "$BIN_DIR/busybox"
download_and_set_permissions "$URL_PAYLOAD_DUMPER" "$BIN_DIR/payload-dumper-go"
download_and_set_permissions "$URL_LPMAKE" "$BIN_DIR/lpmake"
download_and_set_permissions "$URL_LPUNPACK" "$BIN_DIR/lpunpack"
download_and_set_permissions "$URL_FIGLET" "$BIN_DIR/figlet"
download_and_set_permissions "$URL_FONT1" "$BIN_DIR/standard.flf"
download_and_set_permissions "$URL_FONT2" "$BIN_DIR/nancyj.flf"
download_and_set_permissions "$URL_FONT3" "$BIN_DIR/sblood.flf"

# URL to the checksum file
CHECKSUM_FILE="$BIN_DIR/checksum.arkt"
CHECKSUM_AVAILABLE=1  # Assume checksum is available

# Download checksum file
#echo -e "[INFO] Downloading checksum file..."
if ! download_file "$BASE_URL/bin/checksum.arkt" "$CHECKSUM_FILE"; then
    #echo -e "[WARNING] Failed to download checksum file. Continuing without checksum verification!"
    CHECKSUM_AVAILABLE=0  # Set flag to disable checksum verification
elif ! grep -q "=" "$CHECKSUM_FILE"; then
    #echo -e "[WARNING] Checksum file is invalid or empty. Skipping verification!"
    CHECKSUM_AVAILABLE=0  # Mark as unavailable if it's empty or corrupted
fi

if [ -d "$WORK_DIR" ]; then
    # Check if the directory contains any files or only empty folders
	if [ -n "$($BIN_DIR/busybox find "$WORK_DIR" -mindepth 1 -type f 2>/dev/null)" ]; then
        while true; do
            echo -e "\n[WARNING] Existing files found in $WORK_DIR. Choose an option:\n"
            echo -e "1) Delete all existing files from $WORK_DIR and start fresh"
            echo -e "2) Move old files to a backup folder"
            echo -e "3) Exit script\n"
            read -r choice

            case "$choice" in
                1)
                    log "[INFO] Deleting existing files..."
                    $BIN_DIR/busybox rm -rf "$WORK_DIR"/*
                    echo -e "[SUCCESS] Old files deleted."
                    break
                    ;;
                2)
                    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
                    BACKUP_DIR="${WORK_DIR}_backup_$TIMESTAMP"
                    log "[INFO] Moving old files to $BACKUP_DIR..."
                    $BIN_DIR/busybox mkdir -p "$BACKUP_DIR"
                    $BIN_DIR/busybox mv "$WORK_DIR"/* "$BACKUP_DIR"/
                    echo -e "[SUCCESS] Files moved to $BACKUP_DIR."
                    break
                    ;;
                3)
                    log "[INFO] Exiting script. No changes made."
                    exit 0
                    ;;
                *)
                    log "[ERROR] Invalid input. Please select a valid option (1/2/3)."
                    ;;
            esac
        done
    else
        # If only empty folders or no content exists, delete and recreate it
        # log "[INFO] Work directory is empty or contains only empty folders. Cleaning up..."
        $BIN_DIR/busybox rm -rf "$WORK_DIR"
        $BIN_DIR/busybox mkdir -p "$WORK_DIR"
        # log "[SUCCESS] Clean workspace ready."
    fi
fi

if get_payload_zip_path "$1"; then
    log "[INFO] Using payload ZIP: $SELECTED_ZIP_FILE"
    export SELECTED_PAYLOAD_ZIP="$SELECTED_ZIP_FILE"
else
    log "[ERROR] No valid payload zip selected. Exiting.\n"
    exit 1
fi

# Extract the filename (without extension) from the selected ZIP file
ZIP_NAME=$($BIN_DIR/busybox basename "$SELECTED_ZIP_FILE" .zip)
TARGET_DIR="$WORK_DIR/Auto-Installer_${ZIP_NAME}_FASTBOOT_RECOVERY"

# Create the directory
$BIN_DIR/busybox mkdir -p "$TARGET_DIR"

# Unzip only the payload.bin file into the created directory
echo " "
echo -e "Extracting payload.bin"
$BIN_DIR/busybox unzip -o "$SELECTED_ZIP_FILE" "payload.bin" -d "$TARGET_DIR"

# Check if extraction was successful
if [ ! -f "$TARGET_DIR/payload.bin" ]; then
    echo -e "[ERROR] payload.bin not found in the selected ZIP. Exiting."
    exit 1
fi

# Store the extracted payload.bin path in $PAYLOAD_FILE
PAYLOAD_FILE="$TARGET_DIR/payload.bin"

echo -e "payload.bin extraction complete."

log "[INFO] Extracting payload.bin..."
echo " "
if [ -n "$1" ]; then
  $BIN_DIR/payload-dumper-go -l "$PAYLOAD_FILE"
  $BIN_DIR/payload-dumper-go -o "$TARGET_DIR" "$PAYLOAD_FILE" > /dev/null 2>&1 || { log "[ERROR] Extraction failed!"; exit 1; }
else
  $BIN_DIR/payload-dumper-go -o "$TARGET_DIR" "$PAYLOAD_FILE" || { log "[ERROR] Extraction failed!"; exit 1; }
fi
log "[SUCCESS] Extraction completed."

log "[INFO] Generating original checksums..."
for img in system vendor mi_ext odm system_ext product; do
    if [ -f "$TARGET_DIR/${img}.img" ]; then
        $BIN_DIR/busybox mv "$TARGET_DIR/${img}.img" "$TARGET_DIR/${img}_a.img"
    fi
done
checksum_files=()
for img in system vendor mi_ext odm system_ext product; do
    if [ -f "$TARGET_DIR/${img}_a.img" ]; then
        checksum_files+=("$TARGET_DIR/${img}_a.img")
    fi
done
$BIN_DIR/busybox sha256sum "${checksum_files[@]}" > "$TARGET_DIR/original_checksums.txt"
echo -e "[SUCCESS] Checksums generated."

log "[INFO] Calculating total partition size with buffer..."
TOTAL_SIZE=$($BIN_DIR/busybox du -b "${checksum_files[@]}" | $BIN_DIR/busybox awk '{sum += $1} END {print sum + (24 * 1024 * 1024); exit}')
echo -e "Total size (with buffer): $TOTAL_SIZE"

log "[INFO] Creating super.img..."
echo " "
partition_args=()
group_a="super_group_a"
group_b="super_group_b"

add_partition() {
    local part_name=$1
    local img_path=$2
    local part_size=$(wc -c <"$img_path")
    partition_args+=(--partition "${part_name}_a:readonly:${part_size}:${group_a}")
    partition_args+=(--image "${part_name}_a=${img_path}")
    partition_args+=(--partition "${part_name}_b:readonly:0:${group_b}")
}

if [ -f "$TARGET_DIR/mi_ext_a.img" ]; then
    add_partition "mi_ext" "$TARGET_DIR/mi_ext_a.img"
fi
for img in odm product system system_ext vendor; do
    if [ -f "$TARGET_DIR/${img}_a.img" ]; then
        add_partition "$img" "$TARGET_DIR/${img}_a.img"
    fi
done
$BIN_DIR/lpmake \
    --metadata-size 65536 \
    --metadata-slots 3 \
    --device super:9126805504 \
    --super-name super \
    --group ${group_a}:9126805504 \
    --group ${group_b}:9126805504 \
    "${partition_args[@]}" \
    --virtual-ab \
    --output "$TARGET_DIR/super.img"

log "[SUCCESS] super.img created."

log "[INFO] Truncating super.img..."
$BIN_DIR/busybox truncate -s "$TOTAL_SIZE" "$TARGET_DIR/super.img"
echo -e "[SUCCESS] Truncation complete."

log "[INFO] Cleaning up payload.bin extracted img's..."
rm_files=("${checksum_files[@]}" "$PAYLOAD_FILE")
$BIN_DIR/busybox rm -f "${rm_files[@]}"
echo -e "[SUCCESS] Cleanup complete."

log "[INFO] Extracting super.img..."
$BIN_DIR/busybox mkdir -p "$TARGET_DIR/super_extracted"
$BIN_DIR/lpunpack "$TARGET_DIR/super.img" "$TARGET_DIR/super_extracted" || { log "[ERROR] Extraction failed!"; exit 1; }
echo -e "[SUCCESS] super.img extracted."

log "[INFO] Generating new checksums..."
new_checksum_files=()
for img in system vendor mi_ext odm system_ext product; do
    if [ -f "$TARGET_DIR/super_extracted/${img}_a.img" ]; then
        new_checksum_files+=("$TARGET_DIR/super_extracted/${img}_a.img")
    fi
done
$BIN_DIR/busybox sha256sum "${new_checksum_files[@]}" > "$TARGET_DIR/new_checksums.txt"
echo -e "[SUCCESS] Checksums generated."

log "[INFO] Normalizing checksums for comparison..."
$BIN_DIR/busybox sed -E "s|(_a)?\.img|.img|" "$TARGET_DIR/original_checksums.txt" | $BIN_DIR/busybox sed -E "s|$TARGET_DIR|/tmp|" > "$TARGET_DIR/original_checksums_norm.txt"
$BIN_DIR/busybox sed -E "s|(_a)?\.img|.img|" "$TARGET_DIR/new_checksums.txt" | $BIN_DIR/busybox sed -E "s|$TARGET_DIR/super_extracted|/tmp|" > "$TARGET_DIR/new_checksums_norm.txt"

log "[INFO] Comparing checksums..."
$BIN_DIR/busybox diff "$TARGET_DIR/original_checksums_norm.txt" "$TARGET_DIR/new_checksums_norm.txt" || log "[WARNING] Checksum mismatch detected!"
echo -e "[SUCCESS] Checksum comparison complete."

log "[COMPLETED] super.img prepared to use in fastboot/recovery!"

log "[INFO] Cleaning up..."
$BIN_DIR/busybox rm -rf "$TARGET_DIR/super_extracted"
$BIN_DIR/busybox rm -f "$TARGET_DIR/original_checksums.txt" "$TARGET_DIR/new_checksums.txt" "$TARGET_DIR/original_checksums_norm.txt" "$TARGET_DIR/new_checksums_norm.txt" 
echo -e "[SUCCESS] Cleanup complete."

log "[INFO] Now will contrust folder/files and Download Scripts as required for Auto Installer!\n"

$BIN_DIR/busybox mkdir -p "$TARGET_DIR/images" 
$BIN_DIR/busybox mkdir -p "$TARGET_DIR/META-INF/com/google/android" 
$BIN_DIR/busybox mkdir -p "$TARGET_DIR/META-INF/com/arkt" 
$BIN_DIR/busybox mkdir -p "$TARGET_DIR/bin/windows/platform-tools"
$BIN_DIR/busybox mkdir -p "$TARGET_DIR/bin/windows/log-tool" 
$BIN_DIR/busybox mkdir -p "$TARGET_DIR/bin/linux/platform-tools" 
$BIN_DIR/busybox mkdir -p "$TARGET_DIR/ROOT_APK_INSATLL_THIS_ONLY"
$BIN_DIR/busybox mv "$TARGET_DIR"/*.img "$TARGET_DIR/images/"

#still gotta upload to mirror location for fallback
download_with_fallback \
    "$BASE_URL/files/userdata.img" \
    "$BASE_URL/files/userdata.img" \
    "$TARGET_DIR/images/userdata.img" \
    "userdata.img"
	
download_with_fallback \
    "$BASE_URL/files/empty_frp.img" \
    "$BASE_URL/files/empty_frp.img" \
    "$TARGET_DIR/images/empty_frp.img" \
    "empty_frp.img"

download_with_fallback \
    "$BASE_URL/auto-installer-scripts/bin/7zzs" \
    "$BASE_URL/auto-installer-scripts/bin/7zzs" \
    "$TARGET_DIR/META-INF/com/arkt/7zzs" \
    "7zzs"

download_with_fallback \
    "$BASE_URL/auto-installer-scripts/bin/bootctl" \
    "$BASE_URL/auto-installer-scripts/bin/bootctl" \
    "$TARGET_DIR/META-INF/com/arkt/bootctl" \
    "bootctl"

download_with_fallback \
    "$BASE_URL/auto-installer-scripts/bin/busybox" \
    "$BASE_URL/auto-installer-scripts/bin/busybox" \
    "$TARGET_DIR/META-INF/com/arkt/busybox" \
    "busybox"

download_with_fallback \
    "$BASE_URL/auto-installer-scripts/bin/libhidltransport.so" \
    "$BASE_URL/auto-installer-scripts/bin/libhidltransport.so" \
    "$TARGET_DIR/META-INF/com/arkt/libhidltransport.so" \
    "libhidltransport.so"

download_with_fallback \
    "$BASE_URL/auto-installer-scripts/bin/libhwbinder.so" \
    "$BASE_URL/auto-installer-scripts/bin/libhwbinder.so" \
    "$TARGET_DIR/META-INF/com/arkt/libhwbinder.so" \
    "libhwbinder.so"

download_with_fallback \
    "$BASE_URL/auto-installer-scripts/bin/dmsetup" \
    "$BASE_URL/auto-installer-scripts/bin/dmsetup" \
    "$TARGET_DIR/META-INF/com/arkt/dmsetup" \
    "dmsetup"
	
download_with_fallback \
    "$BASE_URL/auto-installer-scripts/bin/make_f2fs" \
    "$BASE_URL/auto-installer-scripts/bin/make_f2fs" \
    "$TARGET_DIR/META-INF/com/arkt/make_f2fs" \
    "make_f2fs"
	
download_with_fallback \
    "$BASE_URL/auto-installer-scripts/bin/mke2fs" \
    "$BASE_URL/auto-installer-scripts/bin/mke2fs" \
    "$TARGET_DIR/META-INF/com/arkt/mke2fs" \
    "mke2fs"

download_with_fallback \
    "$BASE_URL/auto-installer-scripts/update-binary" \
    "$BASE_URL/auto-installer-scripts/update-binary" \
    "$TARGET_DIR/META-INF/com/google/android/update-binary" \
    "update-binary"
	
download_with_fallback \
    "$DERP_BASE_URL/META-INF/com/google/android/updater-script" \
    "$DERP_BASE_URL/META-INF/com/google/android/updater-script" \
    "$TARGET_DIR/META-INF/com/google/android/updater-script" \
    # "updater-script"

download_with_fallback \
    "$BASE_URL/auto-installer-scripts/autoinstaller.conf" \
    "$BASE_URL/auto-installer-scripts/autoinstaller.conf" \
    "$TARGET_DIR/META-INF/autoinstaller.conf" \

download_with_fallback \
    "$DERP_BASE_URL/install_DerpFest_linux.sh" \
    "$DERP_BASE_URL/install_DerpFest_linux.sh" \
    "$TARGET_DIR/install_forge_linux.sh" \
    # "install_forge_linux.sh"
	
download_with_fallback \
    "$DERP_BASE_URL/install_DerpFest_windows.bat" \
    "$DERP_BASE_URL/install_DerpFest_windows.bat" \
    "$TARGET_DIR/install_forge_windows.bat" \
    # "install_forge_windows.bat"
	
download_with_fallback \
    "$DERP_BASE_URL/update_DerpFest_linux.sh" \
    "$DERP_BASE_URL/update_DerpFest_linux.sh" \
    "$TARGET_DIR/update_forge_linux.sh" \
    # "update_forge_linux.sh"
	
download_with_fallback \
    "$DERP_BASE_URL/update_DerpFest_windows.bat" \
    "$DERP_BASE_URL/update_DerpFest_windows.bat" \
    "$TARGET_DIR/update_forge_windows.bat" \
    # "update_forge_windows.bat"

log "[INFO] Downloading Platform-tools and required tools for Auto-Installer-Forge script...\n"

download_with_fallback \
    "https://dl.google.com/android/repository/platform-tools-latest-linux.zip" \
    "$BASE_URL/files/platform-tools-latest-linux.zip" \
    "$TARGET_DIR/bin/linux/platform-tools-linux.zip" \
    "platform-tools-latest-linux.zip"
	
echo -e "[INFO] Extracting Linux platform-tools..."
$BIN_DIR/busybox unzip -q "$TARGET_DIR/bin/linux/platform-tools-linux.zip" -d "$TARGET_DIR/bin/linux/"
log "[SUCCESS] Linux platform-tools extracted.\n"

download_with_fallback \
    "$BASE_URL/files/platform-tools-latest-windows.zip" \
    "$BASE_URL/files/platform-tools-latest-windows.zip" \
    "$TARGET_DIR/bin/windows/platform-tools-windows.zip" \
    "platform-tools-latest-windows.zip"

echo -e "[INFO] Extracting Windows platform-tools..."
$BIN_DIR/busybox unzip -q "$TARGET_DIR/bin/windows/platform-tools-windows.zip" -d "$TARGET_DIR/bin/windows/"
log "[SUCCESS] Windows platform-tools extracted.\n"

download_with_fallback \
    "https://github.com/dEajL3kA/tee-win32/releases/download/1.3.3/tee-win32.2023-11-27.zip" \
    "$BASE_URL/files/tee-win32.2023-11-27.zip" \
    "$TARGET_DIR/bin/windows/tee.zip" \
    "tee-win32.2023-11-27.zip"
	
echo -e "[INFO] Extracting tee for logging in windows..."
$BIN_DIR/busybox unzip -q "$TARGET_DIR/bin/windows/tee.zip" -d "$TARGET_DIR/bin/windows/log-tool/"
log "[SUCCESS] TEE for windows extracted."

log "[INFO] Now will Download KernelSU NEXT and Magisk APK for ROOT access!\n"

download_with_fallback \
    "https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v1.1.1/KernelSU_Next_v1.1.1_12851-release.apk" \
    "$BASE_URL/files/KernelSU_Next_v1.1.1.apk" \
    "$TARGET_DIR/ROOT_APK_INSATLL_THIS_ONLY/KernelSU_Next_v1.1.1.apk" \
    "KernelSU_Next_v1.1.1.apk"

download_with_fallback \
    "https://github.com/topjohnwu/Magisk/releases/download/v30.6/Magisk-v30.6.apk" \
    "$BASE_URL/files/Magisk_v30.6.apk" \
    "$TARGET_DIR/ROOT_APK_INSATLL_THIS_ONLY/Magisk_v30.6.apk" \
    "Magisk-v30.6.apk"

# Call the funtion with magisk apk name
patch_magisk_boot "Magisk_v30.6.apk"

if [ -n "$3" ] && [ -f "$3" ]; then
    echo " "
    log "[INFO] Custom Root Zip argument detected."
    process_custom_root "$3"
else
    log "[INFO] No custom root zip provided, skipping custom kernel integration."
fi

CONF_FILE="$TARGET_DIR/META-INF/autoinstaller.conf"
if [ -n "$2" ] && [ -f "$2" ]; then
    echo -e "Replacing $CONF_FILE from $2"
    cp "$2" "$CONF_FILE"
else
    echo -e "Using default $CONF_FILE"
fi

IMAGES_DIR="$TARGET_DIR/images"

# Generate the new HASH_PAIRS lines
tmp_hashes=$(mktemp)
for img in "$IMAGES_DIR"/*.img; do
  [ -f "$img" ] || continue
  name=$(basename "$img")

  # Skip super.img because its a big file, if verify then it will take alot of time
  [ "$name" = "super.img" ] && continue

  sha1=$($BIN_DIR/busybox sha1sum "$img" | $BIN_DIR/busybox awk '{print $1}')
  echo "  \"images/$name\" \"$sha1\"" >> "$tmp_hashes"
done

$BIN_DIR/busybox sed -i '/^HASH_PAIRS=(/,/^)/ {
  /^HASH_PAIRS=(/!{/^)/!d}
}' "$CONF_FILE"

# Insert new hashes
$BIN_DIR/busybox sed -i "/^HASH_PAIRS=(/r $tmp_hashes" "$CONF_FILE"

if [ -f "$TARGET_DIR/images/ksu-n_boot.img" ]; then
    log "[INFO] Detected custom root image. Adding it to autoinstaller.conf options..."
    $BIN_DIR/busybox sed -i '/"Root with idk" "boot" "dtbo"/i \  "Root with (KSU-N - Kernel SU NEXT)" "ksu-n_boot" "dtbo"' "$CONF_FILE"
    log "[SUCCESS] Added 'Root with (KSU-N - Kernel SU NEXT)' option to installer config."
fi

#echo -e "[INFO] HASH_PAIRS inside autoinstaller.conf block updated with current img's in images folder"

# Extract build date
log "[INFO] Extracting build date from ROM..\n"
raw_build_date=$(strings "$TARGET_DIR/images/super.img" | grep -m 1 'build.date=' | cut -d'=' -f2)
parsed_input=$(echo "$raw_build_date" | $BIN_DIR/busybox sed -E 's/ [A-Z]{3} / /')
parsed_build_date=$($BIN_DIR/busybox date -d "$parsed_input" -D "%a %b %d %T %Y" +"%d %b %Y")
echo -e "Parsed date: $parsed_build_date"
update_field "BUILD_DATE" "Build date" "$parsed_build_date"

log "[SUCCESS] Auto-Installer-Forge files processing finished!\n"

log "[INFO] Now, let's update configration file for this rom!\n"

# fields to update 
#update_field "DEVICE_CODE" "DEVICE CODE"
if [ -n "$2" ] && [ -f "$2" ]; then
    log "[INFO] using config from $2"
    ROOT_TYPE=$(grep '^ROOT_TYPE=' "$CONF_FILE" | cut -d'=' -f2)
else
	update_field "ROM_NAME" "ROM name"
	update_field "ROM_MAINTAINER" "ROM maintainer"
	update_field "ANDROID_VER" "Android version"
	update_field "DEVICE_NAME" "Device name"
	update_field "BUILD_DATE" "Build date"
	update_field "SECURITY_PATCH" "Security patch"
	update_field "ROM_VERSION" "ROM Build version"
    echo -e "\nChoose root method present in ROM:\n"
    echo -e "1) With root (KSU-N - Kernel SU NEXT)"
    echo -e "2) With root (KSU - Kernel SU)"
    echo -e "3) With root (SukiSU-Ultra)"
    echo -e "4) Without root\n"
    while true; do
    echo -n "Enter the number (1-4): "
    read -r ROOT_TYPE
    case $ROOT_TYPE in
        [1-4]) echo; break ;;
        *) echo -e "Invalid input. Please enter a number between 1 and 4.\n" ;;
    esac
    done

    echo -e "\nChoose the default behavior when flashing ROM via recovery:\n"
    echo -e "1) Dirty Flash (Update only - keeps user data)"
    echo -e "2) Clean Flash (Factory reset - wipes all data)\n"
    while true; do
    echo -n "Enter the number (1-2): "
    read -r FORMAT_MODE
    case $FORMAT_MODE in
        1|2) echo; break ;;
        *) echo -e "Invalid input. Please enter 1 or 2.\n" ;;
    esac
    done
    [ "$FORMAT_MODE" -eq 1 ] && FORMAT_MODE=0 || FORMAT_MODE=1
    $BIN_DIR/busybox sed -i "s/^FORMAT_DEFAULT=.*/FORMAT_DEFAULT=$FORMAT_MODE  # set 1 if want format default selected/" "$CONF_FILE"
fi
case "$ROOT_TYPE" in
  1) root="Root with (KSU-N - Kernel SU NEXT)" ;;
  2) root="Root with (KSU - Kernel SU)" ;;
  3) root="Root with (SukiSU-Ultra)" ;;
  4) root="Without root" ;;
  *) root="Root with (KSU-N - Kernel SU NEXT)" ;;
esac

bases_linux=(install_forge_linux.sh update_forge_linux.sh)
bases_windows=(install_forge_windows.bat update_forge_windows.bat)

# Update root method in Linux flasher scripts
$BIN_DIR/busybox sed -i "s|Root with idk|$root|g" "$CONF_FILE"
for base in "${bases_linux[@]}"; do
  [ -f "$TARGET_DIR/$base" ] && \
  $BIN_DIR/busybox sed -i "s/^root=\".*\"/root=\"$root\"/" "$TARGET_DIR/$base"
done
# Update root method in Windows flasher scripts
for base in "${bases_windows[@]}"; do
  [ -f "$TARGET_DIR/$base" ] && \
  $BIN_DIR/busybox sed -i "s/^set root=.*/set root=$root/" "$TARGET_DIR/$base"
done

# Extract Rom Maintainer value from config
maintainer=$(grep '^ROM_MAINTAINER=' "$CONF_FILE" | sed -n 's/^ROM_MAINTAINER="\([^"]*\)".*/\1/p')

# Update Maintainer value in Linux flasher scripts
for base in "${bases_linux[@]}"; do
  [ -f "$TARGET_DIR/$base" ] && \
  $BIN_DIR/busybox sed -i "s/^ROM_MAINTAINER=\".*\"/ROM_MAINTAINER=\"$maintainer\"/" "$TARGET_DIR/$base"
done
# Update Maintainer value in Windows flasher scripts
for base in "${bases_windows[@]}"; do
  [ -f "$TARGET_DIR/$base" ] && \
  $BIN_DIR/busybox sed -i "s/^set ROM_MAINTAINER=.*/set ROM_MAINTAINER=$maintainer/" "$TARGET_DIR/$base"
done

# Extract ROM Name value from config
line=$(grep "^ROM_NAME=" "$CONF_FILE")

# Extract value and optional comment
value=$(echo "$line" | $BIN_DIR/busybox sed -n 's/^ROM_NAME="\([^"]*\)".*/\1/p')
#comment=$(echo "$line" | $BIN_DIR/busybox sed -n 's/^ROM_NAME="[^"]*"[[:space:]]*\(.*\)/\1/p')
#echo -e "Current ROM Name: $value"
#echo -e "Sanitized: $(echo "$value" | $BIN_DIR/busybox tr ' ' '_' | $BIN_DIR/busybox tr -cd '[:alnum:]_-')"

# Sanitize ROM name by removing non-alphanum and replace space with _ underscore
sanitized_name=$(echo "$value" | $BIN_DIR/busybox tr ' ' '_' | $BIN_DIR/busybox tr -cd '[:alnum:]_-')

# Generate ASCII and replace in autoinstaller.conf
$BIN_DIR/figlet -f $BIN_DIR/standard.flf -w 100 $value > $BIN_DIR/ascii
$BIN_DIR/busybox sed -i 's#\\#\\\\#g' $BIN_DIR/ascii
$BIN_DIR/busybox sed -i 's/^/"/;s/$/"/' $BIN_DIR/ascii
$BIN_DIR/busybox sed -i '/ASCII_ART_LINES=(/,/^)/ { /ASCII_ART_LINES=(/!{/^)/!d } }' "$CONF_FILE"
$BIN_DIR/busybox sed -i "/ASCII_ART_LINES=(/r $BIN_DIR/ascii" "$CONF_FILE"

# derp it...
# lowercase_derp=$(echo "$value" | $BIN_DIR/busybox tr '[:upper:]' '[:lower:]')
# if echo "$lowercase_derp" | $BIN_DIR/busybox grep -q "derp"; then
#     FIGLET_FONT="$BIN_DIR/sblood.flf"
# else
#     FIGLET_FONT="$BIN_DIR/nancyj.flf"
# fi

# Generate ASCII and replace in Linux flasher scripts
# rm -f $BIN_DIR/ascii
# $BIN_DIR/figlet -f $FIGLET_FONT -w 100 $value > $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i '/^[[:space:]]*$/d' $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i 's/^/    echo -e " /;s/$/"/' $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i '1s/^/    echo\n/' $BIN_DIR/ascii
# for base in "${bases_linux[@]}"; do
#   [ -f "$TARGET_DIR/$base" ] && \
#   $BIN_DIR/busybox sed -i '/print_ascii() {/ { n; N; N; N; N; N; N; d; }' "$TARGET_DIR/$base" && \
#   $BIN_DIR/busybox sed -i "/print_ascii()/r $BIN_DIR/ascii" "$TARGET_DIR/$base"
# done
# rm -f $BIN_DIR/ascii
# $BIN_DIR/figlet -f $FIGLET_FONT -w 100 $value > $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i '/^[[:space:]]*$/d' $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i 's/^/    echo -e " /;s/$/\" | tee -a "$log_file"/' $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i '1s/^/    echo\n/' $BIN_DIR/ascii
# for base in "${bases_linux[@]}"; do
#   [ -f "$TARGET_DIR/$base" ] && \
#   $BIN_DIR/busybox sed -i '/print_log_ascii() {/ { n; N; N; N; N; N; N; d; }' "$TARGET_DIR/$base" && \
#   $BIN_DIR/busybox sed -i "/print_log_ascii()/r $BIN_DIR/ascii" "$TARGET_DIR/$base"
# done

# Generate ASCII and replace in Windows flasher scripts
# rm -f $BIN_DIR/ascii
# $BIN_DIR/figlet -f $FIGLET_FONT -w 100 $value > $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i '/^[[:space:]]*$/d' $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i 's/^/echo /' $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i '1s/^/echo.\n/' $BIN_DIR/ascii
# for base in "${bases_windows[@]}"; do
#   [ -f "$TARGET_DIR/$base" ] && \
#   $BIN_DIR/busybox sed -i '/^:print_ascii[[:space:]]*$/ { n; N; N; N; N; N; N; d; }' "$TARGET_DIR/$base" && \
#   $BIN_DIR/busybox sed -i "/^:print_ascii[[:space:]]*$/r $BIN_DIR/ascii" "$TARGET_DIR/$base"
# done
# rm -f $BIN_DIR/ascii
# $BIN_DIR/figlet -f $FIGLET_FONT -w 100 $value > $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i '/^[[:space:]]*$/d' $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i 's/^/call :log  " /;s/$/"/' $BIN_DIR/ascii
# $BIN_DIR/busybox sed -i '1s/^/echo.\n/' $BIN_DIR/ascii
# for base in "${bases_windows[@]}"; do
#   [ -f "$TARGET_DIR/$base" ] && \
#   $BIN_DIR/busybox sed -i '/^:print_log_ascii[[:space:]]*$/ { n; N; N; N; N; N; N; d; }' "$TARGET_DIR/$base" && \
#   $BIN_DIR/busybox sed -i "/^:print_log_ascii[[:space:]]*$/r $BIN_DIR/ascii" "$TARGET_DIR/$base"
# done

# Rename auto-insatller scripts file with new rom name
all_bases=("${bases_linux[@]}" "${bases_windows[@]}")
for base in "${all_bases[@]}"; do
  src="$TARGET_DIR/$base"
  if [ -f "$src" ]; then
    new_name=$(echo "$base" | $BIN_DIR/busybox sed "s/forge/$sanitized_name/")
    $BIN_DIR/busybox mv "$src" "$TARGET_DIR/$new_name"
    #echo -e "Renamed: $base → $new_name"
  fi
done

# Convert .sh and .bat files (once, after renaming)
for file in "$TARGET_DIR"/*.sh "$TARGET_DIR"/*.bat; do
  [ -f "$file" ] || continue
  case "$file" in
    *.sh)  $BIN_DIR/busybox dos2unix "$file" ;;
    *.bat) $BIN_DIR/busybox dos2unix -d "$file" ;;
  esac
done

$BIN_DIR/busybox dos2unix "$CONF_FILE"
log "[INFO] Cleaning up..."
$BIN_DIR/busybox rm -f "$tmp_hashes" "$TARGET_DIR/bin/linux/platform-tools-linux.zip" "$TARGET_DIR/bin/windows/platform-tools-windows.zip" "$TARGET_DIR/bin/windows/tee.zip"
cd
rm -rf $BIN_DIR
echo -e "[SUCCESS] Cleanup complete."

log "[NOTE] you can also change configrations in META-INF/autoinstaller.conf file anytime!"
log "[COMPLETED] Auto-Installer-Forge process finished successfully!\n"
