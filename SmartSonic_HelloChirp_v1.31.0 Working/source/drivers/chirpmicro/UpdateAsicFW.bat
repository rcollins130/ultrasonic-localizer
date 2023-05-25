@echo off

set __asic_pn_=ch101
set __asic_fw_name_=floor
set __asic_fw_version=v11

choice /M "About to update ASIC FW for %__asic_pn_% / %__asic_fw_name_% / %__asic_fw_version%"
if errorlevel 2 exit /b

:: Search for 7-zip executable
where /q 7z.exe
if errorlevel 1 (
    FOR %%i IN ("%ProgramFiles%\7-Zip" "%ProgramFiles(x86)%\7-Zip") DO IF EXIST %%~si\NUL set "seven_zip=%%~si\7z.exe"
) ELSE (
    set seven_zip=7z.exe
)

if "%seven_zip%" == "" (
	echo [ERROR] 7zip not found, please install in standard location or add it to path
	pause & exit /b 1
)

set "__local_asic_fw_package_release_location_=\\ussjc-share01\swdpackages\invn\chirpmicro\asic\%__asic_pn_%\%__asic_fw_name_%"
set "__local_asic_fw_package_name_=invn.chirpmicro.asic.%__asic_pn_%.%__asic_fw_name_%.%__asic_fw_version%.zip"

:: Download ASIC FW release package
rmdir /S /Q tmp 2>NUL
xcopy /Y "%__local_asic_fw_package_release_location_%\%__local_asic_fw_package_name_%" tmp\

if not exist "tmp\%__local_asic_fw_package_name_%" (
    echo [ERROR] Copy ASIC FW package from %__local_asic_fw_package_release_location_%\%__local_asic_fw_package_name_% failed
    pause & exit /b 1
)

:: Extract ASIC FW release package
call %seven_zip% -y x "tmp\%__local_asic_fw_package_name_%" -otmp\

:: Copy ASIC FW source code file
xcopy /Y tmp\*.c src\

:: Cleanup ASIC FW release package
rmdir /S /Q tmp 2>NUL

pause
