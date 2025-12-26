:: This batch script builds duplicate-remover on Windows systems.
:: It builds both the CLI and GUI version.

@echo off

:: Validate input and check if we can build at all.

set programVersion=
set release=false

if [%1] == [] (
    echo "Please specify the version (e.g. 1.0.0) as the first parameter"
    goto :eof
)

WHERE dub > $null 2>&1
if %ERRORLEVEL% neq 0 (
    echo Cannot execute `dub`.
    echo Install the D programming language to build duplicate-remover:
    echo        https://dlang.org/download.html
)

set programVersion=%1%

:: Build the program.

echo Building duplicate-remover %programVersion% CLI...
dub build -c cli

echo Building duplicate-remover %programVersion% GUI...
dub build -c gui-windows

:: Rename binaries to subfolders

set cliName=duplicate-remover-cli_%programVersion%_win_x64
set guiName=duplicate-remover-gui_%programVersion%_win_x64

mkdir "./bin/%cliName%" 
mkdir "./bin/%guiName%" 

echo f | xcopy /Q /Y /F "./bin/duplicate_remover_cli.exe" "./bin/%cliName%/%cliName%.exe"
echo f | xcopy /Q /Y /F "./bin/duplicate_remover_gui.exe" "./bin/%guiName%/%guiName%.exe"

:: Copy dependencies

robocopy "./lib/windows" "./bin/%guiName%" /S *.dll > $null 2>&1