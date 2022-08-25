#!/bin/bash

set -e

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### Reinstall kernel modules
for dir in FuelGauge EEPROM; do
    cd $BASEDIR/$dir
    ./install.sh
done
