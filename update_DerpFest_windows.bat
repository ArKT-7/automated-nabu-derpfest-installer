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
set "download_platform_tools_url=https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
set "platform_tools_zip=bin\windows\platform-tools.zip"
set "extract_folder=bin\windows"
set "download_tee_url=https://github.com/dEajL3kA/tee-win32/releases/download/1.3.3/tee-win32.2023-11-27.zip"
set "tee_zip=bin\windows\tee-win32.2023-11-27.zip"
set "tee_extract_folder=bin\windows\log-tool"
set "check_flag=bin\download.flag"
cls
cls
CALL :print_ascii
if not exist "%check_flag%" (
    goto download_ask
) else ( 
    goto re_download_ask 
)
:re_download_ask
call :get_input "%YELLOW%Do you want to download dependencies again (Y) or %GREEN%continue (C)? %RESET%" download_choice
if /i "%download_choice%"=="y" (
    call :download_dependencies
) else (
    echo %YELLOW%Continuing without downloading dependencies...%RESET%
    goto start
)
:download_ask
call :get_input "%YELLOW%Do you want to download dependencies online or %GREEN%continue? %YELLOW%(Y/C)%RESET%: " download_choice
if /i "%download_choice%"=="y" (
    call :download_dependencies
) else (
    echo %YELLOW%Continuing without downloading dependencies...%RESET%
    goto start
)
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
)
echo %RED%Invalid choice.%RESET% %YELLOW%Please enter 'Y' or 'C'%RESET%
echo.
goto get_input

:download_dependencies
(
    echo.
    echo %YELLOW%Downloading platform-tools...%RESET%
	timeout /t 2 /nobreak >nul
    curl -L "%download_platform_tools_url%" -o "%platform_tools_zip%"
    if %errorlevel% neq 0 (
	    echo.
        echo %RED%curl failed to download.%RESET% %YELLOW%Trying with again...%RESET%
		echo.
        if exist "%platform_tools_zip%" del "%platform_tools_zip%"
		timeout /t 2 /nobreak >nul
        curl -L "%download_platform_tools_url%" -o "%platform_tools_zip%"
    )
    if exist "%platform_tools_zip%" (
	    echo.
        echo Extracting platform-tools...
        mkdir "%extract_folder%"
		timeout /t 2 /nobreak >nul
        tar -xf "%platform_tools_zip%" -C "%extract_folder%"
        del "%platform_tools_zip%"
        echo %GREEN%Platform-tools downloaded and extracted successfully.%RESET%
    ) else (
	    echo.
        echo %YELLOW%Platform-tools could not be downloaded. press any key to continue.%RESET%
        pause
        pause >nul
    )
	echo.
	echo %YELLOW%Downloading tee-log-tool...%RESET%
	timeout /t 2 /nobreak >nul
    curl -L "%download_tee_url%" -o "%tee_zip%"
    if %errorlevel% neq 0 (
	    echo.
        echo %RED%curl failed to download.%RESET% %YELLOW%Trying with again...%RESET%
		echo.
        if exist "%tee_zip%" del "%tee_zip%"
		timeout /t 2 /nobreak >nul
        curl -L "%download_tee_url%" -o "%tee_zip%"
    )
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
        echo %YELLOW%tee could not be downloaded. press any key to continue.%RESET%
        pause >nul
    )
	echo download flag. > "%check_flag%"
)
:start
set "fastboot=bin\windows\platform-tools\fastboot.exe"
set "tee=bin\windows\log-tool\tee-x86.exe"
if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "tee=bin\windows\log-tool\tee-x64.exe"
) else if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "tee=bin\windows\log-tool\tee-a64.exe"
) else if /I "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set "tee=bin\windows\log-tool\tee-x86.exe"
)
if not exist "%fastboot%" (
    echo %RED%%fastboot% not found.%RESET%
	echo.
	echo let's proceed with downloading.
    call :download_dependencies
)
if not exist "%tee%" (
    echo %RED%%tee% not found.%RESET%
	echo.
	echo let's proceed with downloading.
    call :download_dependencies
)
set "log_file=logs\auto-installer_log_%date:/=-%_%time::=-%.txt"
echo. > "%log_file%"
cls
cls
CALL :print_log_ascii
echo.
call :log "%YELLOW%Waiting for device...%RESET%"
set device=unknown
for /f "tokens=2" %%D in ('%fastboot% getvar product 2^>^&1 ^| findstr /l /b /c:"product:"') do set device=%%D
if "%device%" neq "nabu" (
    echo.
    call :log "%YELLOW%Compatible devices: nabu%RESET%"
    call :log "%RED%Your device: %device%%RESET%"
	echo.
    call :log "%YELLOW%Please connect your Xiaomi Pad 5 - Nabu%RESET%"
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
echo %YELLOW%1.%RESET% With root (KSU-N - Kernel SU NEXT)
echo %YELLOW%2.%RESET% Without root
echo %YELLOW%3.%RESET% With root (Magisk v29.0)
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
call :log "%YELLOW%Starting installation with KSU-NEXT...%RESET%"
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
call :log "%YELLOW%Starting installation without root...%RESET%"
%fastboot% set_active a 2>&1 | %tee% -a "%log_file%"
echo.
CALL :FlashPartition boot boot.img
CALL :FlashPartition dtbo dtbo.img
goto common_flash
:common_flash
:install_magisk
cls
cls
CALL :print_ascii
CALL :print_note
echo.
call :log "%YELLOW%Starting installation with Magisk...%RESET%"
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
echo @@@@@@@  @@@@@@@@ @@@@@@@  @@@@@@@  @@@@@@@@ @@@@@@@@  @@@@@@ @@@@@@@
echo @@:  @@@ @@:      @@:  @@@ @@:  @@@ @@:      @@:      :@@       @@:  
echo @:@  :@: @:::::   @:@::@:  @:@@:@:  @:::::   @:::::    :@@::    @::  
echo :::  ::: :::      ::: :::  :::      :::      :::          :::   :::  
echo :: :  :  : :: :::  :   : :  :        :       : :: ::: ::.: :     :  
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
call :log  "@@@@@@@  @@@@@@@@ @@@@@@@  @@@@@@@  @@@@@@@@ @@@@@@@@  @@@@@@ @@@@@@@"
call :log  "@@:  @@@ @@:      @@:  @@@ @@:  @@@ @@:      @@:      :@@       @@:  "
call :log  "@:@  :@: @:::::   @:@::@:  @:@@:@:  @:::::   @:::::    :@@::    @::  "
call :log  ":::  ::: :::      ::: :::  :::      :::      :::          :::   :::  "
call :log  ":: :  :  : :: :::  :   : :  :        :       : :: ::: ::.: :     :   "
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
:log
echo %~1 | %tee% -a "%log_file%"
goto :eof