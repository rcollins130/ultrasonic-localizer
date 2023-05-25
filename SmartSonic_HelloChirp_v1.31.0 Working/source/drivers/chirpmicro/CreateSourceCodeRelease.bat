@echo off

if [%1]==[] ( echo Usage: %0 ^<version_number^> & exit /b 1 )

set __release_version__=%1
set "__output_log__=%CD%\release.log"

rem choice /M "About to Generate %__release_version__% release package"
rem if errorlevel 2 exit /b

echo.
echo Chirpmicro SonicLib source code release creator for %__release_version__%
echo.
echo [STEP 1] Generate %__release_version__% Doxygen documentation
call doxygen --version >nul 2>&1 || ( echo [ERROR] Doxygen not found in PATH & exit /b 1 )
rmdir /S /Q html 2> nul
pushd inc > nul
( type Doxyfile & echo PROJECT_NUMBER=%__release_version__% ) | doxygen - > %__output_log__% 2>&1
popd

rem Search for 7-zip executable
where /q 7z.exe
if errorlevel 1 (
    for %%i in ("%ProgramFiles%\7-Zip" "%ProgramFiles(x86)%\7-Zip") do if exist %%~si\nul set "seven_zip=%%~si\7z.exe"
) else (
    set seven_zip=7z.exe
)
if "%seven_zip%" == "" (
    echo [ERROR] 7zip not found, please install in standard location or add it to PATH
    exit /b 1
)
set "__release_folder__=release"
set "__release_zipfile__=%__release_folder__%\SonicLib_%__release_version__%.zip"
echo [STEP 2] Generate SonicLib_%__release_version__%.zip archive
del /F %__release_zipfile__% 2> nul
call %seven_zip% -y a -tzip %__release_zipfile__% html inc src LICENSE.txt >> %__output_log__%

set "__iexpress_sedfile__=soniclib_install.sed"
set "__iexpress_full_sedfile__=%__iexpress_sedfile__%.full.tmp"
pushd %__release_folder__% > nul
del /F %__iexpress_full_sedfile__% 2> nul
echo [STEP 3] Generate SonicLib_%__release_version__%.exe self-extracting archive
type %__iexpress_sedfile__% > %__iexpress_full_sedfile__%
echo TargetName=SonicLib_%__release_version__%.exe >> %__iexpress_full_sedfile__%
echo FriendlyName=Chirp SonicLib %__release_version__% >> %__iexpress_full_sedfile__%
echo FILE0=SonicLib_%__release_version__%.zip >> %__iexpress_full_sedfile__%
call iexpress /Q /N %__iexpress_full_sedfile__%
popd

echo.
echo [DONE] Release %__release_version__% files are available in /release folder
