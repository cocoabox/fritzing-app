#!/bin/bash -e
QTBIN=/usr/local/opt/qt6/bin

# Go to this scripts directory and then one up
toolsdir=$(dirname "${BASH_SOURCE[0]}")
cd "$toolsdir"/..
workingdir=$(pwd)

if [[ ! -f phoenix.pro ]]; then
    echo run this script in the GIT ROOT directory >&2
    exit 1
fi

echo ">> working directory"
echo "$workingdir"

deploydir=$workingdir/../deploy-app
echo ">> deploy directory"
echo "$deploydir"
rm -rf "$deploydir"
mkdir "$deploydir"

builddir=$workingdir/../release64  # this is pre-defined by Qt
echo ">> build directory"
echo "$builddir"

echo ">> building fritzing from working directory"
$QTBIN/qmake -o Makefile phoenix.pro
make "-j$(sysctl -n machdep.cpu.thread_count)" release  # release is the type of build
cp -r "$builddir/Fritzing.app" "$deploydir"

supportdir=$deploydir/Fritzing.app/Contents/MacOS
echo ">> support directory"
echo "$supportdir"

echo ">> copy support files"
cd "$workingdir"
cp -rf sketches help translations INSTALL.txt README.md LICENSE.CC-BY-SA LICENSE.GPL2 LICENSE.GPL3 "$supportdir/"

echo ">> clean translations"
cd "$supportdir"
rm -f ./translations/*.ts  			# remove translation xml files, since we only need the binaries in the release
find ./translations -name "*.qm" -size -128c -delete   # delete empty translation binaries

if [[ -d ../fritzing-parts ]]; then
    echo ">> symlink parts repository"
    [[ -L "./fritzing-parts" ]] && rm ./fritzing-parts 
    ln -s ../fritzing-parts ./fritzing-parts
else
    echo ">> clone parts repository"
    git clone --branch master --single-branch https://github.com/fritzing/fritzing-parts.git
fi
echo ">> build parts database"
./Fritzing -db "fritzing-parts/parts.db"  # -pp "fritzing-parts" -f "."

echo ">> add .app dependencies"
cd "$deploydir"
$QTBIN/macdeployqt Fritzing.app -verbose=2 -dmg

echo ">> launch Fritzing"
cd "$deploydir"
open Fritzing.dmg

echo ">> done!"
