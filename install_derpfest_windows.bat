@echo off
setlocal enabledelayedexpansion
title Derpfest Auto-Installer 3.0
cd %~dp0

CALL :print_ascii

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set RED=%ESC%[91m
set YELLOW=%ESC%[93m
set GREEN=%ESC%[92m
set RESET=%ESC%[0m

set required_files=boot.img dtbo.img ksu-n_boot.img ksu-n_dtbo.img magisk_boot.img super.img userdata.img vbmeta.img vbmeta_system.img vendor_boot.img

if not exist "images" (
    echo %RED%ERROR! Please extract the zip again. 'images' folder is missing.%RESET%
	echo.
    echo %YELLOW%Press any key to exit...%RESET%
    pause > nul
    exit /b
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
	echo %RED%ERROR! Please extract the zip again. One or more required files are missing in the 'images' folder.%RESET%
	echo.
    echo %YELLOW%Press any key to exit...%RESET%
    pause > nul
    exit /b
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
) else if /i "%download_choice%"=="c" (
    echo %YELLOW%Continuing without downloading dependencies...%RESET%
	goto start
) else (
    echo.
    echo %RED%Invalid choice.%RESET% %YELLOW%Please enter 'Y' to download or 'C' to continue.%RESET%
    goto re_download_ask
)
:download_ask
call :get_input "%YELLOW%Do you want to download dependencies online or %GREEN%continue? %YELLOW%(Y/C)%RESET%: " download_choice

if /i "%download_choice%"=="y" (
    call :download_dependencies
) else if /i "%download_choice%"=="c" (
    echo %YELLOW%Continuing without downloading dependencies...%RESET%
	goto start
) else (
    echo.
    echo %RED%Invalid choice.%RESET% %YELLOW%Please enter 'Y' to download or 'C' to continue.%RESET%
    goto download_ask
)
:get_input
setlocal
set /p input=%~1
if "%input%"=="" (
    goto start
    goto :get_input
) else if /i not "%input%"=="y" if /i not "%input%"=="c" (
    echo %RED%Invalid choice.%RESET% %YELLOW%Please enter 'Y' to download or 'C' to continue.%RESET%
    goto :get_input
)
endlocal & set "%~2=%input%"
exit /b
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
set "log_file=logs\derpfest_log_%date:/=-%_%time::=-%.txt"
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
    pause
    exit /B 1
)
cls
cls
CALL :print_ascii
call :log "%GREEN%Device detected. Proceeding with installation...%RESET%"
echo.
call :log "%RED%NOTE! - %YELLOW%You are going to wipe your data and internal storage.%RESET%"
call :log "%RED%NOTE! - %YELLOW%It will delete all your files and photos stored on internal storage.%RESET%"
echo.
set /p choice=Do you agree? %YELLOW%(Y/N)%RESET% 
if /i "%choice%" neq "y" exit
echo.
:choose_method
call :log "%YELLOW%Choose installation method:%RESET%"
echo.
echo %YELLOW%1.%RESET% Without root
echo %YELLOW%2.%RESET% With root (KSU-N - Kernel SU NEXT)
echo %YELLOW%3.%RESET% With root (Magisk 29.0)
echo.
set /p install_choice=%YELLOW%Enter option (1, 2, or 3):%RESET% 

if "%install_choice%"=="1" goto install_no_root
if "%install_choice%"=="2" goto install_ksu-n
if "%install_choice%"=="3" goto install_magisk
echo.
call :log "%RED%Invalid option. %YELLOW%Please try again.%RESET%"
echo.
goto choose_method
:install_no_root
cls
cls
CALL :print_ascii
CALL :print_note
echo.
call :log "%YELLOW%Starting installation without root...%RESET%"
%fastboot% set_active a 2>&1 | %tee% -a "%log_file%"
echo.
CALL :FlashPartition dtbo dtbo.img
CALL :FlashPartition vbmeta vbmeta.img
CALL :FlashPartition vbmeta_system vbmeta_system.img
CALL :FlashPartition boot boot.img
goto common_flash
:install_ksu-n
cls
cls
CALL :print_ascii
CALL :print_note
echo.
call :log "%YELLOW%Starting installation with KSU...%RESET%"
%fastboot% set_active a 2>&1 | %tee% -a "%log_file%"
echo.
CALL :FlashPartition dtbo ksu-n_dtbo.img
CALL :FlashPartition vbmeta vbmeta.img
CALL :FlashPartition vbmeta_system vbmeta_system.img
CALL :FlashPartition boot ksu-n_boot.img
goto common_flash
:install_magisk
cls
cls
CALL :print_ascii
CALL :print_note
echo.
call :log "%YELLOW%Starting installation with Magisk...%RESET%"
%fastboot% set_active a 2>&1 | %tee% -a "%log_file%"
echo.
CALL :FlashPartition dtbo dtbo.img
CALL :FlashPartition vbmeta vbmeta.img
CALL :FlashPartition vbmeta_system vbmeta_system.img
CALL :FlashPartition boot magisk_boot.img
goto common_flash
:common_flash
cls
cls
echo.
CALL :print_ascii
CALL :print_note
echo.
CALL :FlashPartition vendor_boot vendor_boot.img
cls
cls
echo.
CALL :print_ascii
CALL :print_note
echo.
call :log "%YELLOW%Flashing super%RESET%"
%fastboot% flash super images\super.img 2>&1 | %tee% -a "%log_file%"
echo.
call :log "%YELLOW%Erasing metadata%RESET%"
%fastboot% erase metadata 2>&1 | %tee% -a "%log_file%"
echo.
call :log "%YELLOW%Flashing userdata%RESET%"
%fastboot% flash userdata images\userdata.img 2>&1 | %tee% -a "%log_file%"
echo.
call :log "%YELLOW%Erasing userdata%RESET%"
%fastboot% erase userdata 2>&1 | %tee% -a "%log_file%"
echo.
REM call :log "%YELLOW%Erasing frp (fix)%RESET%"
%fastboot% erase frp 2>&1 | %tee% -a "%log_file%"
%fastboot% reboot 2>&1 | %tee% -a "%log_file%"
goto finished
:finished
echo.
echo.
CALL :print_log_ascii
echo.
call :log "%GREEN%Installation is complete! Your device has rebooted successfully.%RESET%"
echo.
set /p "=%YELLOW%Press any key to exit%RESET%" <nul
pause >nul
exit
:print_ascii
echo.
echo  @@@@@@@  @@@@@@@@ @@@@@@@  @@@@@@@  @@@@@@@@ @@@@@@@@  @@@@@@ @@@@@@@
echo  @@:  @@@ @@:      @@:  @@@ @@:  @@@ @@:      @@:      :@@       @@:  
echo  @:@  :@: @:::::   @:@::@:  @:@@:@:  @:::::   @:::::    :@@::    @::  
echo  :::  ::: :::      ::: :::  :::      :::      :::          :::   :::  
echo  :: :  :  : :: :::  :   : :  :        :       : :: ::: ::.: :     :  
echo.
echo                               P.A.N.Z.
echo Script By, @ArKT_7                                     
echo.
EXIT /B
:print_note
echo ######################################################################
echo %YELLOW%  WARNING: Do not click on this window, as it will pause the process%RESET%
echo %YELLOW%  Please wait, Device will auto reboot when installation is finished.%RESET%
echo ######################################################################
EXIT /B
:print_log_ascii
echo.
call :log  "@@@@@@@  @@@@@@@@ @@@@@@@  @@@@@@@  @@@@@@@@ @@@@@@@@  @@@@@@ @@@@@@@"
call :log  "@@:  @@@ @@:      @@:  @@@ @@:  @@@ @@:      @@:      :@@       @@:  "
call :log  "@:@  :@: @:::::   @:@::@:  @:@@:@:  @:::::   @:::::    :@@::    @::  "
call :log  ":::  ::: :::      ::: :::  :::      :::      :::          :::   :::  "
call :log  ":: :  :  : :: :::  :   : :  :        :       : :: ::: ::.: :     :   "
echo.
call :log  "                             P.A.N.Z.                                " 
call :log  "Script By - @ArKT_7"
echo.
EXIT /B
:FlashPartition
SET partition=%1
SET image=%2
call :log "%YELLOW%Flashing %partition%%RESET%"
%fastboot% flash %partition%_a images\%image% 2>&1 | %tee% -a "%log_file%"
%fastboot% flash %partition%_b images\%image% 2>&1 | %tee% -a "%log_file%"
echo.
EXIT /B
:log
echo %~1 | %tee% -a "%log_file%"
goto :eof
