from config import INDEX_SECTOR_START
from config import INDEX_SECTOR_COUNT

# from config import DATA_SECTOR_START
from config import SECTOR_SIZE
from config import INDEX_SIZE

# from config import DATA_SECTOR_COUNT

from superblock import Superblock
from index import Index

import math


class SFS(object):
    def __init__(self, image_file, name="SFS.DISK"):
        """Create a new filesystem object"""

        self.fd = open(image_file, "rb+")
        self.sb = Superblock(name)

        self.idx_first_flag = True
        self.idx_file_num = 0
        self.idx_lba = INDEX_SECTOR_START
        self.idx = None

    def __del__(self):
        """When object closed in memory, release the file handle"""

        self.fd.close()

    def format(self):
        """Format the virtual disk image with the Simple File System disk format."""

        self.sb.save(self.fd)
        self.fd.seek(INDEX_SECTOR_START * SECTOR_SIZE)

        # Clear out the indexes first
        for i in range(INDEX_SECTOR_START, (INDEX_SECTOR_START + INDEX_SECTOR_COUNT)):
            self.fd.write(bytearray(SECTOR_SIZE))

        for drive in range(1, 9):
            for filenum in range(256):
                idx_pos = (
                    (INDEX_SECTOR_START * SECTOR_SIZE)
                    + ((drive - 1) * 16 * SECTOR_SIZE)
                    + (filenum * INDEX_SIZE)
                )
                # print(hex(idx_pos), hex(int(idx_pos / 512)))
                self.fd.seek(idx_pos)
                self.fd.write(Index.blankindex(drive, filenum))

    def read_index(self, drive: int):
        """Reads the next index in the formatted file system.

        @param: drive int The Drive number to work on.
        @return False on error, or the Index
        """

        if self.idx_first_flag:
            self.idx_first_flag = False
            self.idx_lba = INDEX_SECTOR_START + ((drive) * 16)
            self.idx_file_num = 0
        else:
            self.idx_file_num += 1
            if self.idx_file_num % 16 == 0:
                self.idx_lba += 1
            if self.idx_file_num > 255:
                return False

        self.fd.seek(self.idx_lba * SECTOR_SIZE)
        block = self.fd.read(SECTOR_SIZE)

        idx = Index(
            block[
                (self.idx_file_num % 16)
                * INDEX_SIZE : ((self.idx_file_num % 16) * INDEX_SIZE)
                + INDEX_SIZE
            ]
        )
        return idx

    def find_free_index(self, drive: int):
        self.idx_first_flag = True
        while 1:
            idx = self.read_index(drive)
            if idx:
                if idx.file_attr in [0xE5, 0xFF]:
                    self.idx = idx
                    return True
                else:
                    continue
            else:
                return False

    def find(self, drive: int, filename: str):
        self.idx_first_flag = True
        fname = bytes(filename.split(".")[0], encoding="ascii")
        fext = bytes(filename.split(".")[1], encoding="ascii")
        while 1:
            idx = self.read_index(drive)
            if idx:
                if fname == idx.fname and fext == idx.fext:
                    self.idx = idx
                    return True
            else:
                return False

    def create(self, drive: int, filename: str):
        if self.find(drive, filename):
            self.idx.fname = filename.split(".")[0]
            self.idx.fext = filename.split(".")[1]
            self.idx.file_attr = 0x40
            return True
        elif self.find_free_index(drive):
            self.idx.fname = filename.split(".")[0]
            self.idx.fext = filename.split(".")[1]
            self.idx.file_attr = 0x40
            return True
        else:
            return False

    def write(self, data):
        if len(data) > 0x1FFFF:
            print(f"Data length to write is {len(data)} bytes...")
            return False
        # add more metadata about the file.
        self.idx.sec_count = math.ceil(len(data) / SECTOR_SIZE)
        self.idx.last_offset = len(data) % SECTOR_SIZE
        # All files have a load address in front.
        self.idx.laddr = int.from_bytes(data[0:2], byteorder="little")
        if self.idx.fext.upper() == "COM":
            # if it's a com file then set the exec address same as load address
            self.idx.exec_addr = int.from_bytes(data[0:2], byteorder="little")
        data = data[2:]
        # update the length last as we are removing bytes from the input data
        # to replace inside the metadata.  Up to 4 bytes are removed.
        self.idx.file_size = len(data)
        self.idx.flush(self.fd)

        seekpos_lba = ((self.idx.drive) * 0x10000) + (self.idx.file_num * 0x100)
        self.fd.seek(seekpos_lba * SECTOR_SIZE)
        self.fd.write(data)
        return True

    def read(self):
        seekpos_lba = (self.idx.drive * 0x10000) + (self.idx.file_num * 0x100)
        self.fd.seek(seekpos_lba * SECTOR_SIZE)
        return self.fd.read(self.idx.file_size)

    """ Given a path to an 8k binary file copies the file into the SDCARD image
    at sector 1 up to sector 17 """

    def copy_os(self, path):
        with open(path, "rb") as src:
            src.seek(8192)
            data = src.read()
            if len(data) != 8192:
                print("OS BINARY FILE AFTER SKIPPING 8192 IS NOT 8192 BYTES long")
                return
            self.fd.seek(512, 0)
            self.fd.write(data)
