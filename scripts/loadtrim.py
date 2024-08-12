#!/usr/bin/env python3
import sys

in_file = open(sys.argv[1], "rb")
out_file = open(sys.argv[2], "wb")
page = sys.argv[3]

binary_input = in_file.read()
in_file.close()
out_file.write(bytearray(int(page, base=16).to_bytes(2, "little")))
out_file.write(binary_input)
out_file.close()
