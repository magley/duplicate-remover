#!/bin/bash
#
# This shell script builds duplicate-remover on Linux systems.
# It builds both the CLI and GUI version.
#
# Usage:
#
#      build.sh version [--release] [--zip]
#          version     Version of the program as a string. Example: 1.0.0
#          --release   If set, the release build is compiled
#          --zip       If set, the builds will be zipped (.zip) 
#
#

# Validate input and check if we can build at all.

programVersion=
release=false
shouldZip=false

if [ -z "$1" ]; then
    echo "Please specify the version (e.g. 1.0.0) as the first parameter"
    exit 1
fi

for arg in $@; do
    if [ "$arg" = "--release" ]; then release=true; fi
    if [ "$arg" = "--zip" ]; then shouldZip=true; 
    fi
done

if ! command -v dub &> /dev/null
then
    echo Cannot execute \`dub\`
    echo Install the D programming language to build duplicate-remover:
    echo        https://dlang.org/download.html
    exit 1
fi

programVersion=$1

# Build the program

if [ "$release" ]; then
    releaseFlag="--build=release"
fi

echo "Building duplicate-remover" $programVersion "CLI..."
dub build $releaseFlag -c cli

echo "Building duplicate-remover" $programVersion "GUI..."
dub build $releaseFlag -c gui-linux

# Rename binaries to subfolders

cliName="duplicate-remover-cli_${programVersion}_linux_x64"
guiName="duplicate-remover-gui_${programVersion}_linux_x64"

mkdir -p "./bin/${cliName}"
mkdir -p "./bin/${guiName}"

mv "./bin/duplicate_remover_cli" "./bin/${cliName}/${cliName}"
mv "./bin/duplicate_remover_gui" "./bin/${guiName}/${guiName}"

# Copy dependencies

find ./lib/linux/ -name \*.so -exec cp {} "./bin/${guiName}/" \;