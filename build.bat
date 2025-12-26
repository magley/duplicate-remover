::
:: This batch script builds duplicate-remover on Windows systems.
:: It builds both the CLI and GUI version.
::
:: Usage:
::
::      build.bat version [--release] [--zip]
::          version     Version of the program as a string. Example: 1.0.0
::          --release   If set, the release build is compiled
::          --zip       If set, the builds will be zipped (.zip) 
::
::

@echo off

:: Validate input and check if we can build at all.

set programVersion=
set release=false
set shouldZip=false

if [%1] == [] (
    echo "Please specify the version (e.g. 1.0.0) as the first parameter"
    goto :eof
)

for %%p in (%*) do (
    if "%%p" == "--release" set release=true
    if "%%p" == "--zip" set shouldZip=true
)

WHERE dub >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Cannot execute `dub`.
    echo Install the D programming language to build duplicate-remover:
    echo        https://dlang.org/download.html
    goto :eof
)

set programVersion=%1%

:: Build the program.

if %release%==true set releaseFlag="--build=release"

echo Building duplicate-remover %programVersion% CLI...
dub build %releaseFlag% -c cli

echo Building duplicate-remover %programVersion% GUI...
dub build %releaseFlag% -c gui-windows

:: Rename binaries to subfolders

set cliName=duplicate-remover-cli_%programVersion%_win_x64
set guiName=duplicate-remover-gui_%programVersion%_win_x64

if not exist "./bin/%cliName%" mkdir "./bin/%cliName%" 
if not exist "./bin/%guiName%" mkdir "./bin/%guiName%" 

echo f | xcopy /Q /Y /F "./bin/duplicate_remover_cli.exe" "./bin/%cliName%/%cliName%.exe" >nul 2>&1
echo f | xcopy /Q /Y /F "./bin/duplicate_remover_gui.exe" "./bin/%guiName%/%guiName%.exe" >nul 2>&1

:: Copy dependencies.

robocopy "./lib/windows" "./bin/%guiName%" /S *.dll >nul 2>&1

:: Zip the folders, if needed.

if %shouldZip% == true (
    WHERE tar >nul 2>&1
    if %ERRORLEVEL% == 0 (
        powershell "Compress-Archive" "./bin/%cliName%/*" "./bin/%cliName%.zip" >nul 2>&1
        powershell "Compress-Archive" "./bin/%guiName%/*" "./bin/%guiName%.zip" >nul 2>&1
    )
)