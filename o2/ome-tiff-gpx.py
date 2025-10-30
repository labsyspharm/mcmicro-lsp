#!/usr/bin/env python3

# Calculates and prints total area in gigapixels of a single channel of all
# Image elements in an OME-TIFF.

import struct
import sys
import xml.etree.ElementTree

assert len(sys.argv) == 2, "Usage: script.py image.ome.tif"
f = open(sys.argv[1], 'rb')

assert f.read(4) == b'II+\x00', "Can only read little-endian BigTIFF files"
assert struct.unpack('<HH', f.read(4)) == (8, 0), "Unexpected offset/reserved values"
first_ifd_offset, = struct.unpack('<Q', f.read(8))
f.seek(first_ifd_offset)

ntags, = struct.unpack('<Q', f.read(8))
for i in range(ntags):
    tag, dtype, length, offset = struct.unpack('<HHQQ', f.read(20))
    if tag == 270:
        f.seek(offset)
        text = f.read(length)
        if text[-1] == 0:
            text = text[:-1]
        try:
            root = xml.etree.ElementTree.fromstring(text)
        except xml.etree.ElementTree.ParseError:
            assert False, "File is not an OME-TIFF or OME-XML is damaged (XML parse error)"
        ns = {'ome': 'http://www.openmicroscopy.org/Schemas/OME/2016-06'}
        pixels_elts = root.findall('ome:Image/ome:Pixels', ns)
        pixel_total = 0
        for p in pixels_elts:
            assert p.attrib['Type'] == 'uint16', "Can only handle uint16 pixel type"
            sx = int(p.attrib['SizeX'])
            sy = int(p.attrib['SizeY'])
            pixel_total += sx * sy
        assert pixel_total > 0, "File is not an OME-TIFF or OME-XML is damaged (no Image elements)"
        print(pixel_total / 1e9)
        break
else:
    assert False, "No ImageDescription tag found"
