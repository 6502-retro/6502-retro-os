from config import INDEX_SECTOR_START
from config import SECTOR_SIZE
from config import INDEX_SIZE


class Index(object):
    """
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
    | xx   | 18-1F  |                                                                    |
    """

    def __init__(self, barray):
        self.drive = barray[0]
        self.fname = barray[1:9].strip()
        self.fext = barray[9:12].strip()
        self.laddr = int.from_bytes(barray[12:13], byteorder="little")
        self.sec_count = barray[14]
        self.file_num = barray[15]
        self.file_attr = barray[16]
        self.exec_addr = int.from_bytes(barray[17:19], byteorder="little")
        self.last_offset = int.from_bytes(barray[19:21], byteorder="little")
        self.file_size = int.from_bytes(barray[21:24], byteorder="little")

    @staticmethod
    def name2filename(filename: str):
        name_bytes = f"{filename[:8]}".ljust(8, " ")
        return name_bytes

    @staticmethod
    def ext2extension(extension: str):
        extension_bytes = f"{extension[:3]}".ljust(3, " ")
        return extension_bytes

    @staticmethod
    def blankindex(drive: int, file_num: int):
        return b"".join(
            [
                bytearray(drive.to_bytes(1, "little")),  # 1
                bytearray(Index.name2filename(""), encoding="ascii"),  # 8 = 9
                bytearray(Index.ext2extension(""), encoding="ascii"),  # 3 = 12
                bytearray(0x00.to_bytes(2, "little")),  # 2 = 14
                bytearray(0x00.to_bytes(1, "little")),  # 1 = 15
                bytearray(file_num.to_bytes(1, "little")),  # 1 = 16
                bytearray(0xE5.to_bytes(1, "little")),  # 1 = 17
                bytearray(0x00.to_bytes(2, "little")),  # 2 = 19
                bytearray(0x00.to_bytes(2, "little")),  # 2 = 21
                bytearray(0x00.to_bytes(3, "little")),  # 3 = 24
            ]
        )

    def index2ba(self):
        return b"".join(
            [
                bytearray(self.drive.to_bytes(1, "little")),
                bytearray(Index.name2filename(self.fname), encoding="ascii"),
                bytearray(Index.ext2extension(self.fext), encoding="ascii"),
                bytearray(self.laddr.to_bytes(2, "little")),
                bytearray(self.sec_count.to_bytes(1, "little")),
                bytearray(self.file_num.to_bytes(1, "little")),
                bytearray(self.file_attr.to_bytes(1, "little")),
                bytearray(self.exec_addr.to_bytes(2, "little")),
                bytearray(self.last_offset.to_bytes(2, "little")),
                bytearray(self.file_size.to_bytes(3, "little")),
            ]
        )

    def flush(self, fd):
        seekpos = (INDEX_SECTOR_START + ((self.drive -1) * 16)) * SECTOR_SIZE + (
            self.file_num * INDEX_SIZE
        )
        fd.seek(seekpos)
        fd.write(self.index2ba())
