@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "BUILD_CONFIG=%~1"
set "BUILD_PLATFORM=%~2"

if "%BUILD_CONFIG%"=="" set "BUILD_CONFIG=Debug"
if "%BUILD_PLATFORM%"=="" set "BUILD_PLATFORM=Win32"

call "D:\Embarcadero RAD Studio\23.0\bin\rsvars.bat"
if errorlevel 1 exit /b %errorlevel%

pushd "%ROOT_DIR%"

echo Building Sempare.TemplateEngine.Playground.dproj with RS23 (%BUILD_CONFIG% %BUILD_PLATFORM%)...
msbuild "demo\SempareTemplatePlayground\Sempare.TemplateEngine.Playground.dproj" /t:Clean /p:Config=%BUILD_CONFIG% /p:Platform=%BUILD_PLATFORM%
if errorlevel 1 goto :fail

msbuild "demo\SempareTemplatePlayground\Sempare.TemplateEngine.Playground.dproj" /t:Build /p:Config=%BUILD_CONFIG% /p:Platform=%BUILD_PLATFORM%
if errorlevel 1 goto :fail

popd
exit /b 0

:fail
set "ERR=%ERRORLEVEL%"
popd
exit /b %ERR%
