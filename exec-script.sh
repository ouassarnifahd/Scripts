#!/usr/bin/env bash
if [[ $# -ne 2 ]]; then
    echo "usage: `basename $0` <cible.sh> <ExecFile>"
    exit;
fi
cp $1 /usr/local/bin/$2 && chmod +x $1
