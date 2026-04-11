#!/bin/bash
#
# Copyright (C) 2025-26 https://github.com/ArKT-7/Auto-Installer-Forge
#
# Made for flashing Android ROMs easily
#
cd "$(dirname "$0")"

ESC="\033"
RED="${ESC}[91m"
YELLOW="${ESC}[93m"
GREEN="${ESC}[92m"
RESET="${ESC}[0m"

ROM_MAINTAINER="P.A.N.Z."
required_files=("boot.img" "dtbo.img" "ksu-n_boot.img" "magisk_boot.img" "super.img" "userdata.img" "vbmeta.img" "vbmeta_system.img" "vendor_boot.img")
root="Without root"

print_ascii() {
    echo
    echo -e "█████▄ ▓█████  ██▀███   ██▓███    █████▒▓█████   ██████ ▄▄▄█████▓ "
    echo -e "▒██▀ ██▌▓█   ▀ ▓██ ▒ ██▒▓██░  ██▒▓██   ▒ ▓█   ▀ ▒██    ▒ ▓  ██▒ ▓▒"
    echo -e "░██   █▌▒███   ▓██ ░▄█ ▒▓██░ ██▓▒▒████ ░ ▒███   ░ ▓██▄   ▒ ▓██░ ▒░"
    echo -e "░▓█▄   ▌▒▓█  ▄ ▒██▀▀█▄  ▒██▄█▓▒ ▒░▓█▒  ░ ▒▓█  ▄   ▒   ██▒░ ▓██▓ ░ "
    echo -e "░▒████▓ ░▒████▒░██▓ ▒██▒▒██▒ ░  ░░▒█░    ░▒████▒▒██████▒▒  ▒██▒ ░ "
    echo -e " ▒▒▓  ▒ ░░ ▒░ ░░ ▒▓ ░▒▓░▒▓▒░ ░  ░ ▒ ░    ░░ ▒░ ░▒ ▒▓▒ ▒ ░  ▒ ░░   "
    echo -e " ░ ▒  ▒  ░ ░  ░  ░▒ ░ ▒░░▒ ░      ░       ░ ░  ░░ ░▒  ░ ░    ░    "
    echo -e " ░ ░  ░    ░     ░░   ░ ░░        ░ ░       ░   ░  ░  ░    ░      "
    echo
    echo -e "This rom built by: ${ROM_MAINTAINER}"
    echo
    echo -e "Flasher/Installer by: ArKT"
    echo
}
print_note() {
    echo -e "##################################################################"
    echo -e "${YELLOW}Please wait. The device will reboot when installation is finished.${RESET}"
    echo -e "##################################################################"
}
print_log_ascii() {
    echo
    echo -e "█████▄ ▓█████  ██▀███   ██▓███    █████▒▓█████   ██████ ▄▄▄█████▓ " | tee -a "$log_file"
    echo -e "▒██▀ ██▌▓█   ▀ ▓██ ▒ ██▒▓██░  ██▒▓██   ▒ ▓█   ▀ ▒██    ▒ ▓  ██▒ ▓▒" | tee -a "$log_file"
    echo -e "░██   █▌▒███   ▓██ ░▄█ ▒▓██░ ██▓▒▒████ ░ ▒███   ░ ▓██▄   ▒ ▓██░ ▒░" | tee -a "$log_file"
    echo -e "░▓█▄   ▌▒▓█  ▄ ▒██▀▀█▄  ▒██▄█▓▒ ▒░▓█▒  ░ ▒▓█  ▄   ▒   ██▒░ ▓██▓ ░ " | tee -a "$log_file"
    echo -e "░▒████▓ ░▒████▒░██▓ ▒██▒▒██▒ ░  ░░▒█░    ░▒████▒▒██████▒▒  ▒██▒ ░ " | tee -a "$log_file"
    echo -e " ▒▒▓  ▒ ░░ ▒░ ░░ ▒▓ ░▒▓░▒▓▒░ ░  ░ ▒ ░    ░░ ▒░ ░▒ ▒▓▒ ▒ ░  ▒ ░░   " | tee -a "$log_file"
    echo -e " ░ ▒  ▒  ░ ░  ░  ░▒ ░ ▒░░▒ ░      ░       ░ ░  ░░ ░▒  ░ ░    ░    " | tee -a "$log_file"
    echo -e " ░ ░  ░    ░     ░░   ░ ░░        ░ ░       ░   ░  ░  ░    ░      " | tee -a "$log_file"
    echo
    echo -e "This rom built by: ${ROM_MAINTAINER}" | tee -a "$log_file"
    echo
    echo -e "Flasher/Installer by: ArKT" | tee -a "$log_file"
    echo
}
FlashPartition() {
    local partition="$1"
    local image="$2"
    echo -e "${YELLOW}Flashing ${partition}${RESET}" | tee -a "$log_file"
    $fastboot flash "${partition}_a" "images/${image}" 2>&1 | tee -a "$log_file"
    $fastboot flash "${partition}_b" "images/${image}" 2>&1 | tee -a "$log_file"
    echo
}
platform_tools_url="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
platform_tools_zip="bin/platform-tools.zip"
extract_folder="bin/linux/"
check_flag="bin/download.flag"
download_dependencies() {
    echo
    echo -e "${YELLOW}Attempting to download platform tools...${RESET}"
    if command -v wget &> /dev/null; then
        echo -e "Using wget to download platform tools..."
        if wget "$platform_tools_url" -O "$platform_tools_zip"; then
            echo -e "${GREEN}Download successful using wget.${RESET}"
        else
            echo -e "${RED}wget failed. Trying to download using curl...${RESET}"
            curl -L "$platform_tools_url" -o "$platform_tools_zip" || echo -e "curl download failed."
        fi
    else
        echo -e "${YELLOW}wget is not installed. Trying to download using curl...${RESET}"
        curl -L "$platform_tools_url" -o "$platform_tools_zip" || echo -e "curl download failed."
    fi
    if [ -d "$extract_folder" ]; then
        echo -e "Removing existing platform-tools directory..."
        rm -rf "$extract_folder"
    fi
    echo -e "Extracting platform tools..."
    mkdir -p "$extract_folder"
    unzip -q "$platform_tools_zip" -d "$extract_folder"
    rm "$platform_tools_zip"
    echo "download flag." > "$check_flag"
}
print_ascii
if [ ! -d "images" ]; then
    echo -e "${RED}ERROR! Please extract the zip again. 'images' folder is missing.${RESET}"
    echo
    echo -e "Press any key to exit..."
    read -n 1 -s
    exit 1
fi
missing=false
missing_files=()
for f in "${required_files[@]}"; do
    if [ ! -f "images/$f" ]; then
        echo -e "${YELLOW}Missing: $f${RESET}"
        missing=true
        missing_files+=("$f")
    fi
done
if [ "$missing" = true ]; then
    echo
    echo -e "${RED}Missing files: ${missing_files[*]}${RESET}"
    echo
    echo -e "${RED}ERROR! Please extract the zip again. One or more required files are missing in the 'images' folder.${RESET}"
    echo
    echo -e "Press any key to exit..."
    read -n 1 -s
    exit 1
fi
if [ ! -d "logs" ]; then
    mkdir -p "logs"
fi
if [ ! -d "bin" ]; then
    mkdir -p "bin"
fi
if [ ! -d "$base_dir/bin/linux" ]; then
    mkdir -p "bin/linux"
fi
clear
print_ascii
get_input() {
  local prompt="$1"
  local input
  while true; do
    read -rp "$(echo -e "${prompt}")" input
    input="${input,,}"
    if [[ -z "$input" ]]; then
      input="c"
    fi
    first_char="${input:0:1}"
    if [[ "$first_char" == "y" ]]; then
      echo "y"
      return 0
    elif [[ "$first_char" == "c" || "$first_char" == "n" ]]; then
      echo "c"
      return 0
    else
      echo -e "${RED}Invalid choice.${RESET} ${YELLOW}Please enter 'Y' to download or 'C' to cancel.${RESET}"
      echo
    fi
  done
}
fastboot="${extract_folder}platform-tools/fastboot"
check_fastboot() {
    if [ -f "$fastboot" ]; then
        chmod +x "$fastboot"
        if "$fastboot" --version &> /dev/null; then
            return 0
        fi
    fi
    return 1
}
if ! check_fastboot; then
  choice=$(get_input "${YELLOW}Dependency (fastboot) missing or corrupted. Download it now? ${GREEN}(Y/C): ${RESET}")
  if [[ "$choice" == "y" ]]; then
    download_dependencies
    if ! check_fastboot; then
        echo
        echo -e "${RED}ERROR! Failed to set up fastboot properly after downloading${RESET}"
        echo -e "Installation aborted"
        echo -e "Press any key to exit..."
        read -n 1 -s
        exit 1
    fi
  else
    echo
    echo -e "${RED}Cannot proceed without fastboot dependency${RESET}"
    echo -e "Installation cancelled"
    echo -e "Press any key to exit..."
    read -n 1 -s
    exit 1
  fi
fi
log_file="logs/auto-installer_log_$(date +'%Y-%m-%d_%H-%M-%S').txt"
clear
print_log_ascii
echo -e "${YELLOW}Waiting for device...${RESET}" | tee -a "$log_file"
device_pulse=$($fastboot getvar product 2>&1)
device=$(echo "$device_pulse" | grep -oP '(?<=product: )\S+')
if [[ "$device_pulse" == *"no link"* ]]; then
    echo
    echo -e "${YELLOW}fastboot output: $device_pulse${RESET}" | tee -a "$log_file"
    echo
    echo -e "${YELLOW}Please restart to bootloader Mode (Fastboot on screen), reconnect, and re-run Auto-Installer${RESET}" | tee -a "$log_file"
    echo -e "${YELLOW}For manually rebooting to bootloader, keep pressing Power + Volume Down Button${RESET}" | tee -a "$log_file"
    echo -e "${YELLOW}Then Re-run the Auto-Installer${RESET}" | tee -a "$log_file"
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi
if [ "$device" != "nabu" ]; then
    echo
    echo -e "${RED}Is it nabu?${RESET}" | tee -a "$log_file"
    echo -e "${RED}Is it really our beloved Xiaomi Pad 5?${RESET}" | tee -a "$log_file"
    echo -e "${YELLOW}Device is not recognized as 'nabu - Xiaomi Pad 5'${RESET}" | tee -a "$log_file"
    echo -e "${YELLOW}Device details: $device_pulse${RESET}" | tee -a "$log_file"
    echo -e "${RED}You need to connect Xiaomi Pad 5 (nabu)${RESET}" | tee -a "$log_file"
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi
unlocked_hope=$($fastboot getvar unlocked 2>&1)
unlocked=$(echo "$unlocked_hope" | grep -oP '(?<=unlocked: )\S+')
if [ "$unlocked" != "yes" ]; then
    echo
    if [ "$unlocked" == "no" ]; then
        echo -e "${YELLOW}Bootloader is locked.${RESET}" | tee -a "$log_file"
    else
        echo -e "${YELLOW}Unknown bootloader state detected.${RESET}" | tee -a "$log_file"
    fi
    echo -e "${YELLOW}Please unlock the bootloader and re-run the Auto-Installer${RESET}" | tee -a "$log_file"
    choice=$(get_input "\nNeed help unlocking bootloader? open bootloader unlock guide ${YELLOW}No(n) - Yes(y)${RESET}: ")
    if [[ "$choice" == "y" ]]; then
        echo -e "${YELLOW}Redirecting to bootloader unlock guide...\n${RESET}" | tee -a "$log_file"
        echo -e "${YELLOW}in case browser not open. Please ctrl + click below or copy the link manually.\n${RESET}" | tee -a "$log_file"
        echo -e "${YELLOW}Link: https://github.com/ArKT-7/ArKT-Guides/blob/main/Xiaomi-unlock-bootloader-en.md${RESET}" | tee -a "$log_file"
        if command -v xdg-open &> /dev/null; then
            xdg-open "https://github.com/ArKT-7/ArKT-Guides/blob/main/Xiaomi-unlock-bootloader-en.md" &> /dev/null
        elif command -v python3 &> /dev/null; then
            python3 -m webbrowser "https://github.com/ArKT-7/ArKT-Guides/blob/main/Xiaomi-unlock-bootloader-en.md" &> /dev/null
        fi
    else
        echo -e "${YELLOW}Ok then bye, meet you again, hope you unlock your device first\n${RESET}" | tee -a "$log_file"
    fi
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi
clear
print_ascii
echo -e "${GREEN}Device detected. Proceeding with installation...${RESET}" | tee -a "$log_file"
echo
echo
while true; do
    echo
    echo -e "${YELLOW}Choose installation method:${RESET}" | tee -a "$log_file"
    echo
    echo -e "${YELLOW}1.${RESET} Root with (KSU-N - Kernel SU NEXT)"
    echo -e "${YELLOW}2.${RESET} $root"
    echo -e "${YELLOW}3.${RESET} Root with (Magisk v30.7)"
    echo -e "${YELLOW}4.${RESET} Cancel Flashing ROM"
    echo
    read -p "Enter option (1, 2, 3 or 4): " install_choice
    install_choice=$(echo -e "$install_choice" | xargs)
    if [[ ! "$install_choice" =~ ^[1-4]$ ]]; then
        echo -e "${RED}Invalid option, ${YELLOW}Please try again.${RESET}" | tee -a "$log_file"
        continue
    fi
    case $install_choice in
        1)
            clear    
            print_ascii
            print_note
            echo
            echo -e "${YELLOW}Starting installation Root with (KSU-N - Kernel SU NEXT)...${RESET}" | tee -a "$log_file"
            $fastboot set_active a  2>&1 | tee -a "$log_file"
			echo
            FlashPartition boot ksu-n_boot.img
            FlashPartition dtbo dtbo.img
            break
            ;;
        2)
            clear    
            print_ascii
            print_note
            echo
            echo -e "${YELLOW}Starting installation $root...${RESET}" | tee -a "$log_file"
            $fastboot set_active a  2>&1 | tee -a "$log_file"
			echo
            FlashPartition boot boot.img
            FlashPartition dtbo dtbo.img
            break
            ;;
        3)
            clear    
            print_ascii
            print_note
            echo
            echo -e "${YELLOW}Starting installation with Magisk v30.7...${RESET}" | tee -a "$log_file"
            $fastboot set_active a  2>&1 | tee -a "$log_file"
			echo
            FlashPartition boot magisk_boot.img
            FlashPartition dtbo dtbo.img
            break
            ;;
        4)
           exit
    esac
done
clear
echo    
print_ascii
print_note
echo
FlashPartition vendor_boot vendor_boot.img
FlashPartition vbmeta vbmeta.img
FlashPartition vbmeta_system vbmeta_system.img
clear    
print_ascii
print_note
echo
echo -e "${YELLOW}Flashing super${RESET}" | tee -a "$log_file"
$fastboot flash super images/super.img 2>&1 | tee -a "$log_file"
echo
$fastboot reboot 2>&1 | tee -a "$log_file"
echo
echo
print_log_ascii
echo
echo -e "${GREEN}Installation is complete! Your device has rebooted successfully.${RESET}" | tee -a "$log_file"
echo
read -n 1 -s -r -p "Press any key to exit..."
exit