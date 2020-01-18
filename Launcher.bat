@echo off >NUL
@SETLOCAL enableextensions enabledelayedexpansion
pushd %~dp0
:check_Permissions
    net session >nul 2>&1
    if %errorLevel% == 0 (
		goto Sanity
    ) else (
        echo Insufficient Permissions: You must run this program as administrator.
    )

    pause >nul
exit


:Sanity
IF NOT EXIST "%~dp0setupfiles\directory.txt" goto FirstPass
GOTO SETUP

:FirstPass
FOR /f "delims=/" %%a IN ('reg query "HKLM\System\CurrentControlSet\Services\freelan service" /v "ImagePath" 2^>NUL' ) DO (
 FOR /f "tokens=1,2,*delims= " %%b IN ("%%a") DO IF "%%b"=="ImagePath" (
    FOR %%m IN ("%%~dpd.") DO ECHO %%~dpm> "%~dp0setupfiles\directory.txt"
 )
)
GOTO FileTest

:FileTest
IF NOT EXIST "%~dp0setupfiles\directory.txt" goto ERROR
GOTO SETUP

:ERROR
echo It appears that FreeLAN is not installed.
echo This program is required to play online again.
echo Accept anything that pops up throughout install to avoid errors.
echo Press any button to begin installing the program
pause>NUL

:Install FreeLAN
start /WAIT "" "%~dp0setupfiles\freelan-2.2.0-amd64-install.exe"
goto Sanity


:SETUP
IF EXIST "%~dp0setupfiles\complete.txt" goto SanityTwo
cd setupfiles
set /p remotefiles=<directory.txt
set "localfiles=freelan.cfg"
set "configlocation=%remotefiles%config\"
IF NOT EXIST "%localfiles%\complete.txt" (
xcopy /y "%localfiles%" "%configlocation%">NUL
echo Configuration Completed > complete.txt
)
cd..
:SanityTwo
tasklist | find /i "freelan.exe" >nul 2>&1
IF ERRORLEVEL 1 (
goto :Origin
) ELSE (
taskkill /F /IM freelan.exe >NUL
goto :Origin
)

:ORIGIN
cls
echo Welcome to the Splinter Cell Direct Connection App!
echo Are you the host, or a player of the session...
echo NOTE: If you are a host, you must have UDP 12000 port forwarded.
choice /C 12 /n /M "Host [1], Player [2]"
if ERRORLEVEL 2 goto PLAYER
if ERRORLEVEL 1 goto HOST

:HOST
cls
echo Please type your desired passphrase...
SET /P passphrase=
set quoted=^"%passphrase%"^
cd setupfiles
set /p freelandir=<directory.txt
popd
pushd "%freelandir%bin"
start "" "freelan.exe" --security.passphrase %quoted% --tap_adapter.ipv4_address_prefix_length 9.0.0.1/24 --switch.relay_mode_enabled yes --debug
goto LOOP
:QUIT
exit

:Player
cls
echo Choose between the community server, or connecting to a P2P host.
choice /C 12 /n /M "Community [1], P2P [2]"
if ERRORLEVEL 2 goto P2P
if ERRORLEVEL 1 goto Community

:P2P
echo Please type your Player ID number...
echo NOTE: Ask the host what your ID number is.
SET /p clientid=
echo("%clientid%"|findstr "^[\"][-][1-9][0-9]*[\"]$ ^[\"][1-9][0-9]*[\"]$ ^[\"]0[\"]$">nul&&goto firstcheck||goto INVALIDID

:firstcheck
if %clientid% gtr 1 if %clientid% leq 254 (goto APPROVED)

:INVALIDID
echo You have entered an Invalid ID... Please try again...
pause
goto :Player

:APPROVED
echo Please enter the passphrase...
SET /P passphrase=
set quoted=^"%passphrase%"^
echo Please enter the host's Public IP Address...
SET /p hostip=

:ClientConnection
cd setupfiles
set /p freelandir=<directory.txt
popd
pushd "%freelandir%bin"
start "" "freelan.exe" --security.passphrase %quoted% --fscp.contact %hostip%:12000 --tap_adapter.ipv4_address_prefix_length 9.0.0.%clientid%/24 --debug
goto LOOP

:Community
cd setupfiles
set /p freelandir=<directory.txt
popd
pushd "%freelandir%bin"
start "" "freelan.exe" --security.passphrase "scnetwork" --fscp.contact 209.51.170.152:12000 --tap_adapter.dhcp_proxy_enabled no --tap_adapter.ipv4_dhcp true --debug
goto LOOP

:LOOP
cls
echo Waiting for Splinter Cell To Launch...
tasklist | find /i "SCCT_VERSUS.exe" >nul 2>&1
IF ERRORLEVEL 1 (
  Timeout /T 1 /Nobreak >NUL
  GOTO LOOPTWO
) ELSE (
  GOTO LOOPTHREE
)

:LOOPTWO
cls
echo Waiting for Splinter Cell To Launch...
tasklist | find /i "splintercell3.exe" >nul 2>&1
IF ERRORLEVEL 1 (
  Timeout /T 1 /Nobreak >NUL
  GOTO LOOP
) ELSE (
  GOTO LOOPFOUR
)

:LOOPTHREE
cls
echo Monitoring Game...
tasklist | find /i "SCCT_VERSUS.exe" >nul 2>&1
IF ERRORLEVEL 1 (
  GOTO QUIT
) ELSE (
  Timeout /T 1 /Nobreak >NUL
  GOTO LOOPTHREE
)

:LOOPFOUR
cls
echo Monitoring Game...
tasklist | find /i "splintercell3.exe" >nul 2>&1
IF ERRORLEVEL 1 (
  GOTO QUIT
) ELSE (
  Timeout /T 1 /Nobreak >NUL
  GOTO LOOPFOUR
)

:QUIT
tasklist | find /i "freelan.exe" >nul 2>&1
IF ERRORLEVEL 1 (
exit
) ELSE (
taskkill /F /IM freelan.exe >NUL
exit
)