#!/usr/bin/env bash
# vim: ts=4 sw=4 et:

rm -fr files
rm -f 6502-retro-sdcard.img

mkdir files
cd files

find ../../basic_prg/ -name "*.bas" -exec cp {} ./ \;
find ../../apps/ -name "*.com" -exec cp {} ./ \;

../cli.py new -i ../6502-retro-sdcard.img
../cli.py format -i ../6502-retro-sdcard.img
for file in *.bas; do ../cli.py cp -i ../6502-retro-sdcard.img -s $file -d d://$file; done

../cli.py cp -i ../6502-retro-sdcard.img -s asm.com     -d a://asm.com
../cli.py cp -i ../6502-retro-sdcard.img -s bankmon.com -d a://bmon.com
../cli.py cp -i ../6502-retro-sdcard.img -s basic.com   -d a://basic.com
../cli.py cp -i ../6502-retro-sdcard.img -s cls.com     -d a://cls.com
../cli.py cp -i ../6502-retro-sdcard.img -s copy.com    -d a://copy.com
../cli.py cp -i ../6502-retro-sdcard.img -s dump.com    -d a://dump.com
../cli.py cp -i ../6502-retro-sdcard.img -s format.com  -d a://format.com
../cli.py cp -i ../6502-retro-sdcard.img -s msbasic.com -d a://msbasic.com
../cli.py cp -i ../6502-retro-sdcard.img -s statc.com   -d a://stat.com
../cli.py cp -i ../6502-retro-sdcard.img -s submit.com  -d a://submit.com
../cli.py cp -i ../6502-retro-sdcard.img -s sfmvi.com   -d a://vi.com
../cli.py cp -i ../6502-retro-sdcard.img -s mon.com     -d a://woz.com
../cli.py cp -i ../6502-retro-sdcard.img -s xm.com      -d a://xm.com


cd ../
./cli.py cp -i 6502-retro-sdcard.img -s ../apps/submit/test.sub -d a://test.sub
./cli.py installos -i 6502-retro-sdcard.img -o ../build/rom.raw

