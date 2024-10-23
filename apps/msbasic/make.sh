rm -fr tmp
if [ ! -d tmp ]; then
	mkdir tmp
fi

for i in retro; do

echo $i
ca65 --cpu 65C02 -D $i msbasic.s -o tmp/$i.o &&
ld65 -C $i.cfg tmp/$i.o -o tmp/$i.bin -Ln tmp/$i.lbl
../../scripts/loadtrim.py ./tmp/retro.bin ./tmp/msbasic.com 800
done

