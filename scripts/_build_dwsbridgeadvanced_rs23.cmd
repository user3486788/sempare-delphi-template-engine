@echo off
call "D:\Embarcadero RAD Studio\23.0\bin\rsvars.bat"
msbuild "D:\projects\externals\Sempare\demo\DwsBridgeAdvanced\DwsBridgeAdvanced.dproj" /t:Build /p:Config=Debug /p:Platform=Win32
