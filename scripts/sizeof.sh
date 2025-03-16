#!/usr/bin/bash

BSS=$(cat ../build/rom.map | grep "^BSS" | awk '{ print $4 }')
CODE=$(cat ../build/rom.map | grep "^CODE" | awk '{ print $4 }')
BSSCODE=$((0x$BSS+0x$CODE))
echo  BSS+CODE = ${BSSCODE}
echo Free: $((0x1FFA-${BSSCODE}))
