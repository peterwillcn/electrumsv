#!/bin/bash

NAME_ROOT=ElectrumSV

# These settings probably don't need any change
export WINEPREFIX=/opt/wine64
export PYTHONDONTWRITEBYTECODE=1
export PYTHONHASHSEED=22

PYHOME=c:/python3
PYTHON="wine $PYHOME/python.exe -OO -B"


# Let's begin!
cd `dirname $0`
echo `pwd`
set -e

mkdir -p tmp
cd tmp

pushd $WINEPREFIX/drive_c/electrum

VERSION=`git describe --tags --dirty --always --match sv-*`
echo "Last commit: $VERSION"

find -exec touch -d '2000-11-11T11:11:11+00:00' {} +
popd

cp $WINEPREFIX/drive_c/electrum/LICENCE .

# Install frozen dependencies
$PYTHON -m pip install -r ../../deterministic-build/requirements.txt
$PYTHON -m pip install -r ../../deterministic-build/requirements-hw.txt

pushd $WINEPREFIX/drive_c/electrum
$PYTHON setup.py install
popd

cd ..

rm -rf dist/

# build standalone and portable versions
wine "$PYHOME/scripts/pyinstaller.exe" --noconfirm --ascii --clean --name $NAME_ROOT-$VERSION -w deterministic.spec

# set timestamps in dist, in order to make the installer reproducible
pushd dist
find -exec touch -d '2000-11-11T11:11:11+00:00' {} +
popd

# build NSIS installer
# $VERSION could be passed to the electrum.nsi script, but this would require some rewriting in the script iself.
wine "$WINEPREFIX/drive_c/Program Files (x86)/NSIS/makensis.exe" /DPRODUCT_VERSION=$VERSION electrum.nsi

cd dist
mv ElectrumSV-portable.exe $NAME_ROOT-$VERSION-portable.exe
mv ElectrumSV-setup.exe $NAME_ROOT-$VERSION-setup.exe
mv ElectrumSV.exe $NAME_ROOT-$VERSION.exe
cd ..

echo "Done."
sha256sum dist/Electrum*exe
