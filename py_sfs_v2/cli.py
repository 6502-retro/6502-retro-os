#!/usr/bin/env python3
"""Python script to generate and build an SFS Version 2 disk image
#### Direnet Structure

|..|00|01|02|03|04|05|06|07|08|09|0A|0B|0C|0D|0E|0F|
|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
|00|DD|N1|N2|N3|N4|N5|N6|N7|N8|T1|T2|T3|L1|L2|SC|FN|
|01|FA|E1|E2|Z1|Z2|S2|S1|S0|xx|xx|xx|xx|xx|xx|xx|xx|

#### Dirent Elements

| Code | Offset | Description                                                        |
|----- | -------|--------------------------------------------------------------------|
| DD   | 00-00  | Drive number. 0-7                                                  |
| Nn   | 01-08  | File name. 8 chars                                                 |
| Tn   | 09-0B  | File extension. 3 chars                                            |
| Ln   | 0C-0D  | Load Address. 16 bit address to save file into                     |
| SC   | 0E-0E  | Sector Count. Number of 512byte sectors used by file rounded up)   |
| FN   | 0F-0F  | File Number. The number of the file between 0 and 255              |
| FA   | 10-10  | File Attribute. E5 = deleted                                       |
| En   | 11-12  | Execution Address. Can be zero if file is not executable           |
| Zn   | 13-14  | Last byte offset.  The offset to last byte in the last used sector |
| Sn   | 15-17  | File size. 24 bits                                                 |
| xx   | 18-1F  | Reserved set all to zero                                           |

Directorys on disk

|LBA      | Drive |
|---------|-------|
|0x80-0x8F| A     |
|0x90-0x9F| B     |
|0xA0-0xAF| C     |
|0xB0-0xBF| D     |
|0xC0-0xCF| E     |
|0xD0-0xDF| F     |
|0xE0-0xEF| G     |
|0xF0-0xFF| H     |

Data Sectors on disk


| LBA         | Description    |
|-------------|----------------|
| 00 01 00 00 | A Drive sectors|
| 00 02 00 00 | B Drive sectors|
| 00 03 00 00 | C Drive sectors|
| 00 04 00 00 | D Drive sectors|
| 00 05 00 00 | E Drive sectors|
| 00 06 00 00 | F Drive sectors|
| 00 07 00 00 | G Drive sectors|
| 00 08 00 00 | H Drive sectors|
"""

import click
import os
import sys

from config import SECTOR_SIZE
from config import INDEX_SECTOR_START
from config import DATA_SECTOR_START
from config import DATA_SECTOR_COUNT
from config import INDEX_SIZE

from sfs import SFS


@click.group()
def cli():
    pass


@cli.command()
@click.option(
    "-i", "--image", type=str, help="Path to local SDCARD image", required=True
)
def format(image):
    sfs = SFS(image)
    sfs.format()


@cli.command()
@click.option(
    "-i", "--image", type=str, help="Path to local SDCARD image.", required=True
)
@click.option(
    "-s",
    "--source",
    type=str,
    help="The source. Either <d>://<filename> or ./<filename>",
    required=True,
)
@click.option(
    "-d",
    "--destination",
    type=str,
    help="The destination. Either <d>://<filename> or ./<filename>",
    required=True,
)
def cp(image, source, destination):
    """
    Copies a file from SOURCE to DESTINATION.

    PATHS on the SFS Volume must be prefixed with c://hello.com
    LOCAL PATHS must be either full or relative paths.  Relies on python open() to access.
    """

    if source[1:].startswith("://"):
        source_parts = source[4:].split(".")
        drive = ord(source[0])
        if drive > 0x41 + 8:
            drive -= 0x20
        filename = source_parts[0]
        assert len(filename) < 9, f"ERROR: {filename} must be < 9 chars long."
        extension = source_parts[1]
        assert len(extension) < 4, f"ERROR: {extension} must be < 4 chars long."

        sfs_filename = os.path.basename(source)
        copy_dir = 1  # FROM SFS TO LOCAL
        local_filename = destination

    elif destination[1:].startswith("://"):
        dest_parts = destination[4:].split(".")
        drive = ord(destination[0])
        if drive > 0x41 + 8:
            drive -= 0x20
        filename = dest_parts[0]
        assert len(filename) < 9, f"ERROR: {filename} must be < 9 chars long."
        extension = dest_parts[1]
        assert len(extension) < 4, f"ERROR: {extension} must be < 4 chars long."

        sfs_filename = os.path.basename(destination)
        copy_dir = 0  # FROM LOCAL TO SFS
        local_filename = source
    else:
        print(
            "Either source or destination must start with <d>:// where <d> is a drive letter from A to H"
        )
        sys.exit(1)

    print(f"COPYING {source} to {destination}")

    sfs = SFS(image)
    drive -= 0x40
    if copy_dir == 0:
        if sfs.create(drive - 1, sfs_filename):
            with open(local_filename, "rb") as fd:
                if sfs.write(fd.read()):
                    print(f"Wrote {sfs.idx.file_size} bytes...")
                else:
                    print("Could not save to SFS Image.  Was the file too large?")
                    sys.exit(2)
        else:
            print(f"Couldn not save {local_filename} to {image}")
            sys.exit(2)
    else:
        print(f"DRIVE: {drive}, FILENAME: {sfs_filename}")
        if sfs.find(drive, sfs_filename):
            with open(local_filename, "wb") as fd:
                fd.write(sfs.read())
            print(f"Write {sfs.idx.file_size} bytes...")
        else:
            print("FILE NOT FOUND")


@cli.command()
@click.option(
    "-i", "--image", type=str, help="Path to local SDCARD image.", required=True
)
def new(image):
    """
    Creates a new SFS Disk <IMAGE> and formats it.

    The volume name is "SFS.DISK"
    """
    with open(image, "wb") as fd:
        fd.write(b"\0" * 0x90000 * 0x200)
    sfs = SFS(image)
    sfs.format()


@cli.command()
@click.option(
    "-i", "--image", type=str, help="Path to local SDCARD image.", required=True
)
@click.argument("drive")
def ls(image, drive="A"):
    _drive = ord(drive) - 0x41
    sfs = SFS(image)
    while True:
        idx = sfs.read_index(_drive)
        if not idx:
            break
        if idx.file_attr == 0xE5:
            break

        fname = str(idx.fname, encoding="ascii")
        fext = str(idx.fext, encoding="ascii")
        filename = f"{fname}.{fext}"
        print(f" {chr(idx.drive + 0x40)}:{filename:<11} {idx.file_size:>7} bytes")

    print()


if __name__ == "__main__":
    cli()
