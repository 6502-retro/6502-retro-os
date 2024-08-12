from config import INDEX_SECTOR_START
from config import DATA_SECTOR_START
from config import SECTOR_SIZE


class Superblock(object):
    version = "0002"
    index_start = INDEX_SECTOR_START
    index_last = INDEX_SECTOR_START
    data_start = DATA_SECTOR_START
    signature = bytearray([0xBB, 0x66])

    def __init__(self, id):
        self.id = id
        self.create_block_id()

    def create_block_id(self):
        self.block = b"".join(
            [
                bytearray(self.id, encoding="ascii")[:8],
                bytearray(self.version, encoding="ascii"),
                bytearray(self.index_start.to_bytes(4, "little")),
                bytearray(self.index_last.to_bytes(4, "little")),
                bytearray(self.data_start.to_bytes(4, "little")),
            ]
        )

    def increment_index_last(self):
        self.index_last = self.index_last + 1
        self.create_block()

    def save(self, fd):
        fd.seek(0)
        fd.write(self.block)
        fd.seek(510)
        fd.write(self.signature)
        fd.flush()

    def load(self, fd):
        fd.seek(0)
        block = fd.read(SECTOR_SIZE)
        self.id = block[0:7].decode("ascii")
        self.version = block[8:11].decode("ascii")
        self.index_start = int.from_bytes(block[12:15], byteorder="little")
        self.index_last = int.from_bytes(block[16:19], byteorder="little")
        self.data_start = int.from_bytes(block[20:23], byteorder="little")
        self.signature = block[510:511]
        self.create_block_id()
