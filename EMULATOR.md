# Emulator Instructions

There is a Make recipe for building the SDCARD image needed to run the emulator
or even to simply botostrap your physical media.  The build is based on python
scripts in the `./py_sfs_v2/` folder.  These scripts provide a cli interface to
the SFOS filesystem used.  They require the click library.  Install that with
`pip install click` however you manage your python stuff.

Once you have that working, you should be able to generate an SDCARD with:

``` bash
make make sdcard
```

Then the SDCARD image will be saved to `./py_sfs_v2/6502-retro-sdcard.img`.
This is the image that you pass in as the SDCARD image to the emulator.

For example:

```bash
./6502retro -r <path to rom image> -S 6502-retro-sdcard.img
```
