#!/usr/bin/env bash

rm -fr files
rm sdcard.img
mkdir files
cd files
find ../../apps/ -name "*.com" -exec cp {} ./ \;

../cli.py new -i ../sdcard.img
../cli.py format -i ../sdcard.img
for file in *.com; do ../cli.py cp -i ../sdcard.img -s $file -d a://$file; done
cd ..
./cli.py installos -i sdcard.img -o ../build/rom.raw
