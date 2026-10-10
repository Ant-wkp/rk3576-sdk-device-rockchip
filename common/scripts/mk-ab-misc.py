#!/usr/bin/env python3
"""Generate an initial, unsigned 48 KiB misc image; no hardware access."""
import argparse
from pathlib import Path
import struct
import zlib


def initial_metadata():
    metadata = bytearray(32)
    metadata[:6] = b"\0AB0\1\0"
    metadata[8:12] = bytes((15, 0, 1, 0))
    metadata[12:16] = bytes((14, 7, 0, 0))
    metadata[28:] = struct.pack(">I", zlib.crc32(metadata[:28]))
    return metadata


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    image = bytearray(48 * 1024)
    image[2048:2080] = initial_metadata()
    args.output.write_bytes(image)
