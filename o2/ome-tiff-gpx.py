#!/usr/bin/env python3

# Calculates and prints total area in gigapixels of a single channel of all
# Image elements in an OME-TIFF.

import struct
import sys
import xml.etree.ElementTree

def error(msg):
    print("ERROR:", msg, file=sys.stderr)
    sys.exit(1)

if len(sys.argv) != 2:
    error("Usage: script.py image.ome.tif")
f = open(sys.argv[1], 'rb')

tiff_endian = f.read(2)
if tiff_endian == b'II':
    f_endian = '<'
elif tiff_endian == b'MM':
    f_endian = '>'
else:
    error("Unknown TIFF endian marker")

tiff_version, = struct.unpack(f_endian + 'H', f.read(2))
if tiff_version == 42:
    s_offs = struct.Struct(f_endian + 'I')
    s_ntags = struct.Struct(f_endian + 'H')
    s_tag = struct.Struct(f_endian + 'HHII')
elif tiff_version == 43:
    assert struct.unpack(f_endian + 'HH', f.read(4)) == (8, 0), "Unexpected offset/reserved values"
    s_offs = struct.Struct(f_endian + 'Q')
    s_ntags = struct.Struct(f_endian + 'Q')
    s_tag = struct.Struct(f_endian + 'HHQQ')
else:
    error("Unsupported TIFF version")

first_ifd_offset, = s_offs.unpack(f.read(s_offs.size))
f.seek(first_ifd_offset)

ntags, = s_ntags.unpack(f.read(s_ntags.size))
for i in range(ntags):
    tag, dtype, length, offset = s_tag.unpack(f.read(s_tag.size))
    if tag == 270:
        f.seek(offset)
        text = f.read(length)
        if text[-1] == 0:
            text = text[:-1]
        try:
            root = xml.etree.ElementTree.fromstring(text)
        except xml.etree.ElementTree.ParseError:
            error("File is not an OME-TIFF or OME-XML is damaged (XML parse error)")
        ns = {'ome': 'http://www.openmicroscopy.org/Schemas/OME/2016-06'}
        pixels_elts = root.findall('ome:Image/ome:Pixels', ns)
        if pixels_elts:
            pixel_total = 0
            for p in pixels_elts:
                sx = int(p.attrib['SizeX'])
                sy = int(p.attrib['SizeY'])
                pixel_total += sx * sy
            print(pixel_total / 1e9)
            break
        else:
            error("File is not an OME-TIFF or OME-XML is damaged (no Image elements)")
else:
    error("No ImageDescription tag found")
