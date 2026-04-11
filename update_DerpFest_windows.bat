::
:: Copyright (C) 2025-26 https://github.com/ArKT-7/Auto-Installer-Forge
::
:: Made for flashing Android ROMs easily
::
@echo off
setlocal enabledelayedexpansion
title DerpFest A16 Auto Installer 3.1
cd %~dp0

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set RED=%ESC%[91m
set YELLOW=%ESC%[93m
set GREEN=%ESC%[92m
set RESET=%ESC%[0m

set ROM_MAINTAINER=P.A.N.Z.
set required_files=boot.img dtbo.img ksu-n_boot.img magisk_boot.img super.img userdata.img vbmeta.img vbmeta_system.img vendor_boot.img
set root=Without root

CALL :print_ascii
if not exist "images" (
    echo %RED%ERROR^^! Please extract the zip again. 'images' folder is missing.%RESET%
	echo.
    echo Press any key to exit...
    pause > nul
    exit /b 1
)
set missing=false
set missing_files=
for %%f in (%required_files%) do (
    if not exist "images\%%f" (
        echo %YELLOW%Missing: %%f%RESET%
        set missing=true
        set missing_files=!missing_files! %%f
    )
)
if "!missing!"=="true" (
	echo.
    echo %RED%Missing files: !missing_files!%RESET%
	echo.
	echo %RED%ERROR^^! Please extract the zip again. One or more required files are missing in the 'images' folder.%RESET%
	echo.
    echo Press any key to exit...
    pause > nul
    exit /b 1
)
if not exist "logs" (
    mkdir "logs"
)
if not exist "bin" (
    mkdir "bin"
)
if not exist "bin\windows" (
    mkdir "bin\windows"
)
set "download_platform_tools_url=https://raw.githubusercontent.com/arkt-7/Auto-Installer-Forge/main/files/platform-tools-latest-windows.zip"
set "platform_tools_zip=bin\windows\platform-tools.zip"
set "extract_folder=bin\windows"
set "download_tee_url=https://github.com/dEajL3kA/tee-win32/releases/download/1.3.3/tee-win32.2023-11-27.zip"
set "tee_zip=bin\windows\tee-win32.2023-11-27.zip"
set "tee_extract_folder=bin\windows\log-tool"
set "check_flag=bin\download.flag"
cls
cls
CALL :print_ascii
set "fastboot=bin\windows\platform-tools\fastboot.exe"
set "tee=bin\windows\log-tool\tee-x86.exe"
if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "tee=bin\windows\log-tool\tee-x64.exe"
) else if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "tee=bin\windows\log-tool\tee-a64.exe"
) else if /I "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set "tee=bin\windows\log-tool\tee-x86.exe"
)
call :check_dependencies
if "!deps_ok!"=="false" (
    if not exist "%check_flag%" (
        call :get_input "%YELLOW%Dependency (fastboot/tee) missing or corrupted. Download it online? %GREEN%(Y/C)%RESET%: " download_choice
    ) else (
        call :get_input "%YELLOW%Dependency (fastboot/tee) missing or corrupted. Download it again? %GREEN%(Y/C)%RESET%: " download_choice
    )
    if /i "!download_choice!"=="y" (
        call :download_dependencies
        call :check_dependencies
        if "!deps_ok!"=="false" (
            echo.
            echo %RED%ERROR^^! Failed to set up dependency properly after downloading%RESET%
            echo Installation aborted
            echo Press any key to exit...
            pause > nul
            exit /b 1
        )
    ) else (
        echo.
        echo %RED%Cannot proceed without dependency%RESET%
        echo Installation cancelled
        echo Press any key to exit...
        pause > nul
        exit /b 1
    )
)
goto start
:check_dependencies
set "deps_ok=true"
if not exist "%fastboot%" set "deps_ok=false"
if not exist "%tee%" set "deps_ok=false"
if "!deps_ok!"=="true" (
    "%fastboot%" --version >nul 2>&1
    if !errorlevel! neq 0 set "deps_ok=false"
)
exit /b 0
:get_input
set "input="
set /p input=%~1
if "!input!"=="" (
    set "input=c"
)
set "first_char=!input:~0,1!"
if /i "!first_char!"=="y" (
    endlocal & set "%~2=y"
    exit /b 0
) else if /i "!first_char!"=="c" (
    endlocal & set "%~2=c"
    exit /b 0
) else if /i "!first_char!"=="n" (
    endlocal & set "%~2=c"
    exit /b 0
)
echo %RED%Invalid choice.%RESET% %YELLOW%Please enter 'Y' to download or 'C' to cancel.%RESET%
echo.
goto get_input

:download_dependencies
echo.
echo %YELLOW%Attempting to download platform tools...%RESET%
timeout /t 2 /nobreak >nul
call :download_file "%download_platform_tools_url%" "%platform_tools_zip%"
if exist "%platform_tools_zip%" (
    echo.
    echo Extracting platform tools...
    mkdir "%extract_folder%"
    timeout /t 2 /nobreak >nul
    tar -xf "%platform_tools_zip%" -C "%extract_folder%"
    del "%platform_tools_zip%"
    echo %GREEN%Platform-tools downloaded and extracted successfully.%RESET%
) else (
    echo.
    echo %RED%Download failed.%RESET%
    echo %YELLOW%Platform-tools could not be downloaded.%RESET%
)
echo.
echo %YELLOW%Attempting to download tee-log-tool...%RESET%
timeout /t 2 /nobreak >nul
call :download_file "%download_tee_url%" "%tee_zip%"
if exist "%tee_zip%" (
    echo.
    echo Extracting tee...
    mkdir "%tee_extract_folder%"
    timeout /t 2 /nobreak >nul
    tar -xf "%tee_zip%" -C "%tee_extract_folder%"
    del "%tee_zip%"
    echo %GREEN%tee downloaded and extracted successfully.%RESET%
) else (
    echo.
    echo %RED%Download failed.%RESET%
    echo %YELLOW%tee could not be downloaded.%RESET%
)
echo download flag. > "%check_flag%"
exit /b 0
:start
set "log_file=logs\auto-installer_log_%date:/=-%_%time::=-%.txt"
echo. > "%log_file%"
cls
cls
CALL :print_log_ascii
echo.
call :log "%YELLOW%Waiting for device...%RESET%"
set "device=unknown"
set "no_link=false"
set "device_output="
for /f "delims=" %%A in ('"%fastboot%" getvar product 2^>^&1') do (
    set "line=%%A"
    set "device_output=!device_output! !line!"
    echo !line! | findstr /i /c:"no link" >nul
    if !errorlevel! equ 0 set "no_link=true"
    for /f "tokens=1,2" %%C in ("!line!") do (
        if /i "%%C"=="product:" set "device=%%D"
    )
)
if "!no_link!"=="true" (
    echo.
    call :log "%YELLOW%fastboot output:!device_output!%RESET%"
    echo.
    call :log "%YELLOW%Please restart to bootloader Mode (Fastboot on screen), reconnect, and re-run Auto-Installer%RESET%"
    call :log "%YELLOW%For manually rebooting to bootloader, keep pressing Power + Volume Down Button%RESET%"
    call :log "%YELLOW%Then Re-run the Auto-Installer%RESET%"
    echo.
    echo Press any key to exit...
    pause > nul
    exit /b 1
)
if "!device!" neq "nabu" (
    echo.
    call :log "%RED%Is it nabu?%RESET%"
    call :log "%RED%Is it really our beloved Xiaomi Pad 5?%RESET%"
    call :log "%YELLOW%Device is not recognized as 'nabu - Xiaomi Pad 5'%RESET%"
    call :log "%YELLOW%Device details:!device_output!%RESET%"
    call :log "%RED%You need to connect Xiaomi Pad 5 (nabu)%RESET%"
    echo.
    echo Press any key to exit...
    pause > nul
    exit /b 1
)
set "unlocked=unknown"
for /f "tokens=1,2" %%A in ('"%fastboot%" getvar unlocked 2^>^&1') do (
    if /i "%%A"=="unlocked:" set "unlocked=%%B"
)
if "!unlocked!" neq "yes" (
    echo.
    if "!unlocked!" == "no" (
        call :log "%YELLOW%Bootloader is locked.%RESET%"
    ) else (
        call :log "%YELLOW%Unknown bootloader state detected.%RESET%"
    )
    call :log "%YELLOW%Please unlock the bootloader and re-run the Auto-Installer%RESET%"
    echo.
    call :get_input "Need help unlocking bootloader? open bootloader unlock guide %YELLOW%No(n) - Yes(y)%RESET%: " bl_choice
    if /i "!bl_choice!"=="y" (
        call :log "%YELLOW%Redirecting to bootloader unlock guide...%RESET%"
        echo.
        call :log "%YELLOW%in case browser not open. Please ctrl + click below or copy the link manually.%RESET%"
        echo.
        call :log "%YELLOW%Link: https://github.com/ArKT-7/ArKT-Guides/blob/main/Xiaomi-unlock-bootloader-en.md%RESET%"
        start "" "https://github.com/ArKT-7/ArKT-Guides/blob/main/Xiaomi-unlock-bootloader-en.md"
    ) else (
        call :log "%YELLOW%Ok then bye, meet you again, hope you unlock your device first%RESET%"
        echo.
    )
    echo.
    echo Press any key to exit...
    pause > nul
    exit /b 1
)
cls
cls
CALL :print_ascii
call :log "%GREEN%Device detected. Proceeding with installation...%RESET%"
echo.
echo.
:choose_method
call :log "%YELLOW%Choose installation method:%RESET%"
echo.
echo %YELLOW%1.%RESET% Root with (KSU-N - Kernel SU NEXT)
echo %YELLOW%2.%RESET% %root%
echo %YELLOW%3.%RESET% Root with (Magisk v30.7)
echo %YELLOW%4.%RESET% Cancel Flashing ROM 
echo.
set /p install_choice=Enter option (1, 2, 3 or 4): 

if "%install_choice%"=="1" goto install_ksu-n
if "%install_choice%"=="2" goto install_no_root
if "%install_choice%"=="3" goto install_magisk
if "%install_choice%"=="4" exit
call :log "%RED%Invalid option, %YELLOW%Please try again.%RESET%"
echo.
goto choose_method
:install_ksu-n
cls
cls
CALL :print_ascii
CALL :print_note
echo.
call :log "%YELLOW%Starting installation Root with (KSU-N - Kernel SU NEXT)...%RESET%"
%fastboot% set_active a 2>&1 | %tee% -a "%log_file%"
echo.
CALL :FlashPartition boot ksu-n_boot.img
CALL :FlashPartition dtbo dtbo.img
goto common_flash
:install_no_root
cls
cls
CALL :print_ascii
CALL :print_note
echo.
call :log "%YELLOW%Starting installation %root%...%RESET%"
%fastboot% set_active a 2>&1 | %tee% -a "%log_file%"
echo.
CALL :FlashPartition boot boot.img
CALL :FlashPartition dtbo dtbo.img
goto common_flash
:install_magisk
cls
cls
CALL :print_ascii
CALL :print_note
echo.
call :log "%YELLOW%Starting installation with Magisk v30.7...%RESET%"
%fastboot% set_active a 2>&1 | %tee% -a "%log_file%"
echo.
CALL :FlashPartition boot magisk_boot.img
CALL :FlashPartition dtbo dtbo.img
goto common_flash
:common_flash
cls
cls
echo.
CALL :print_ascii
CALL :print_note
echo.
CALL :FlashPartition vendor_boot vendor_boot.img
CALL :FlashPartition vbmeta vbmeta.img
CALL :FlashPartition vbmeta_system vbmeta_system.img
cls
cls
echo.
CALL :print_ascii
CALL :print_note
echo.
call :log "%YELLOW%Flashing super%RESET%"
%fastboot% flash super images\super.img 2>&1 | %tee% -a "%log_file%"
findstr /i "bad_alloc" "%log_file%" >nul
if !errorlevel! equ 0 (
	echo.
    echo %RED%ERROR^^! There is some Windows Skill issue moment,%RESET%
	echo %YELLOW%Please ask help in telegram group or @ArKT_7%RESET%
	echo.
    pause
)
echo.
%fastboot% reboot 2>&1 | %tee% -a "%log_file%"
goto finished
:finished
echo.
echo.
CALL :print_log_ascii
echo.
call :log "%GREEN%Installation is complete^^^! Your device has rebooted successfully.%RESET%"
echo.
echo Press any key to exit...
pause > nul
exit
:print_ascii
echo.
echo  @@@@@@@  @@@@@@@@ @@@@@@@  @@@@@@@  @@@@@@@@ @@@@@@@@  @@@@@@ @@@@@@@
echo  @@:  @@@ @@:      @@:  @@@ @@:  @@@ @@:      @@:      :@@       @@:  
echo  @:@  :@: @:::::   @:@::@:  @:@@:@:  @:::::   @:::::    :@@::    @::  
echo  :::  ::: :::      ::: :::  :::      :::      :::          :::   :::  
echo  :: :  :  : :: :::  :   : :  :        :       : :: ::: ::.: :     :   
echo.
echo This rom built by: %ROM_MAINTAINER%
echo.
echo Flasher/Installer by: ArKT
echo.
exit /b 1
:print_note
echo ######################################################################
echo %YELLOW%  WARNING: Do not click on this window, as it will pause the process%RESET%
echo %YELLOW%  Please wait, Device will auto reboot when installation is finished.%RESET%
echo ######################################################################
exit /b 1
:print_log_ascii
echo.
call :log  "  @@@@@@@  @@@@@@@@ @@@@@@@  @@@@@@@  @@@@@@@@ @@@@@@@@  @@@@@@ @@@@@@@"
call :log  "  @@:  @@@ @@:      @@:  @@@ @@:  @@@ @@:      @@:      :@@       @@:  "
call :log  "  @:@  :@: @:::::   @:@::@:  @:@@:@:  @:::::   @:::::    :@@::    @::  "
call :log  "  :::  ::: :::      ::: :::  :::      :::      :::          :::   :::  "
call :log  "  :: :  :  : :: :::  :   : :  :        :       : :: ::: ::.: :     :   "
echo.
call :log  "This rom built by: %ROM_MAINTAINER%"
echo.
call :log  "Flasher/Installer by: ArKT"
echo.
exit /b 1
:FlashPartition
SET partition=%1
SET image=%2
call :log "%YELLOW%Flashing %partition%%RESET%"
%fastboot% flash %partition%_a images\%image% 2>&1 | %tee% -a "%log_file%"
%fastboot% flash %partition%_b images\%image% 2>&1 | %tee% -a "%log_file%"
echo.
exit /b 1
:download_file
set "url=%~1"
set "file=%~2"
if exist "%file%" del "%file%"
curl -L "%url%" -o "%file%"
if exist "%file%" exit /b 0
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%url%' -OutFile '%file%' -UseBasicParsing"
if exist "%file%" exit /b 0
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = 3072; (New-Object Net.WebClient).DownloadFile('%url%', '%file%')"
if exist "%file%" exit /b 0
set "abs_file=%CD%\%file%"
bitsadmin /transfer "AutoInstallerDownload" /download /priority normal "%url%" "!abs_file!"
if exist "%file%" exit /b 0
exit /b 1
:log
set "orig=%~1"
set "line=%~1"
set "line=!line:[91m=!"
set "line=!line:[92m=!"
set "line=!line:[93m=!"
set "line=!line:[0m=!"
echo %orig%
echo !line! >> "%log_file%"
goto :eof