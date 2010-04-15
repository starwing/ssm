@set VIMRTDIR=%~dp0
@set VIMRTDIR=%VIMRTDIR:~0,-1%
@set VIMINIT=so %~dp0init.vim
@call ..\..\..\Bin\setenv.bat
@start gvim.exe %*
