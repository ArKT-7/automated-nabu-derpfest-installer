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
    elif [[ "$first_char" == "c" ]]; then
      echo "c"
      return 0
    else
      echo -e "${RED}Invalid choice.${RESET} ${YELLOW}Please enter 'Y' or 'C'${RESET}"
      echo
    fi
  done
}
if [[ ! -f "$check_flag" ]]; then
  choice=$(get_input "${YELLOW}Do you want to download dependencies online or ${GREEN}continue? ${YELLOW}(Y/C): ${RESET}")
  if [[ "$choice" == "y" ]]; then
    download_dependencies
  fi
else
  choice=$(get_input "${YELLOW}Do you want to download dependencies again (Y) or ${GREEN}continue (C)? ${RESET}")
  if [[ "$choice" == "y" ]]; then
    download_dependencies
  fi
fi
fastboot="${extract_folder}/platform-tools/fastboot"
chmod -R +x "$extract_folder"
log_file="logs/auto-installer_log_$(date +'%Y-%m-%d_%H-%M-%S').txt"
if [ ! -f "$fastboot" ]; then
    echo
    echo -e "${RED}$fastboot not found.${RESET}" | tee -a "$log_file"
	echo
	echo -e "let's proceed with downloading." | tee -a "$log_file"
    download_dependencies ;
	chmod -R +x "$extract_folder"
	chmod +x "$fastboot"
fi
clear
print_log_ascii
echo -e "${YELLOW}Waiting for device...${RESET}" | tee -a "$log_file"
device=$($fastboot getvar product 2>&1 | grep -oP '(?<=product: )\S+')
if [ "$device" != "nabu" ]; then
	echo
    echo -e "${YELLOW}Compatible devices: nabu${RESET}" | tee -a "$log_file"
    echo -e "${RED}Your device: $device${RESET}" | tee -a "$log_file"
	echo
    echo -e "${YELLOW}Please connect your Xiaomi Pad 5 - Nabu${RESET}" | tee -a "$log_file"
	echo
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi
clear
print_ascii
echo -e "${GREEN}Device detected. Proceeding with installation...${RESET}" | tee -a "$log_file"
echo
echo -e "${RED}NOTE! - ${YELLOW}You are going to wipe your data and internal storage.${RESET}" | tee -a "$log_file"
echo -e "${RED}NOTE! - ${YELLOW}It will delete all your files and photos stored on internal storage.${RESET}" | tee -a "$log_file"
echo
read -p "Do you agree? (Y/N) " choice
if [[ ! "$choice" =~ ^[Yy]$ ]]; then
    exit 0
fi
while true; do
    echo
    echo -e "${YELLOW}Choose installation method:${RESET}" | tee -a "$log_file"
    echo
    echo -e "${YELLOW}1.${RESET} With root (KSU-N - Kernel SU NEXT)"
    echo -e "${YELLOW}2.${RESET} Without root"
    echo -e "${YELLOW}3.${RESET} With root (Magisk v29.0)"
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
            echo -e "${YELLOW}Starting installation with KSU-NEXT...${RESET}" | tee -a "$log_file"
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
            echo -e "${YELLOW}Starting installation without root...${RESET}" | tee -a "$log_file"
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
            echo -e "${YELLOW}Starting installation with Magisk...${RESET}" | tee -a "$log_file"
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
echo -e "${YELLOW}Erasing metadata${RESET}" | tee -a "$log_file"
$fastboot erase metadata 2>&1 | tee -a "$log_file"
echo
echo -e "${YELLOW}Flashing userdata${RESET}" | tee -a "$log_file"
$fastboot flash userdata images/userdata.img 2>&1 | tee -a "$log_file"
echo
echo -e "${YELLOW}Erasing userdata${RESET}" | tee -a "$log_file"
$fastboot erase userdata 2>&1 | tee -a "$log_file"
echo
#echo -e "${YELLOW}Erasing frp (fix)${RESET}" | tee -a "$log_file"
$fastboot erase frp 2>&1 | tee -a "$log_file"
$fastboot reboot 2>&1 | tee -a "$log_file"
echo
echo
print_log_ascii
echo
echo -e "${GREEN}Installation is complete! Your device has rebooted successfully.${RESET}" | tee -a "$log_file"
echo
read -n 1 -s -r -p "Press any key to exit..."
exit