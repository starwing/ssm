@set VIMRTDIR=%~dp0
@set VIMRTDIR=%VIMRTDIR:~0,-1%
@set VIMINIT=so %~dp0init.vim
@start gvim.exe %*
