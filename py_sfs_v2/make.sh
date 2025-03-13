#!/usr/bin/env bash

rm -fr files
rm sdcard.img
mkdir files
cd files
find ../../apps/ -name "*.com" -exec cp {} ./ \;
find ../../../vgm/ -name "*.vgm" -exec cp {} ./ \;
find ../../basic_prg/ -name "*.bas" -exec cp {} ./ \;

../cli.py new -i ../sdcard.img
../cli.py format -i ../sdcard.img
for file in *.com; do ../cli.py cp -i ../sdcard.img -s $file -d a://$file; done
for file in *.vgm; do ../cli.py cp -i ../sdcard.img -s $file -d e://$file; done
for file in *.bas; do ../cli.py cp -i ../sdcard.img -s $file -d d://$file; done
cd ..
./cli.py installos -i sdcard.img -o ../build/rom.raw
