@echo off

:: Code Size monitoring using IAR
set IAR_FULL_PATH="%IAR_HOME%\common\bin\IarBuild.exe"

:: ** Release build for IoT-Smartsense board
call %IAR_FULL_PATH% test\codesize\chirpmicro-codesize.ewp -clean Release || exit /b 1
call %IAR_FULL_PATH% test\codesize\chirpmicro-codesize.ewp -build Release || exit /b 1
:: ** Memory mapping summary
call "%MBS_LOCAL_REPO%\invn\tool\codesize\1.0.4\release\bin\analyze_code_size.exe" "test\codesize\Release\List\chirpmicro-codesize.map" no OFF 128 128 || exit /b 1
