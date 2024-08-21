#!/usr/bin/env bash

../cli.py new -i ../sdcard.img
../cli.py format -i ../sdcard.img
for file in *.COM; do ../cli.py cp -i ../sdcard.img -s $file -d a://$file; done
for file in *.TXT; do ../cli.py cp -i ../sdcard.img -s $file -d b://$file; done
for file in *.MD; do  ../cli.py cp -i ../sdcard.img -s $file -d c://$file; done
