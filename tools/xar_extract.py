#!/usr/bin/env python3
"""Minimal XAR (.pkg outer container) extractor.

macOS flat .pkg installers are XAR archives. libarchive's xar reader mangles
entry names for some pkgs (e.g. the Cubism Editor installer), so this is a
dependency-free replacement that works on Linux and Termux.

Usage: xar_extract.py <file.pkg> <outdir>
"""
import hashlib
import os
import struct
import sys
import xml.etree.ElementTree as ET
import zlib
import bz2
import lzma


def decode(data, encoding):
    if encoding is None or "octet-stream" in encoding:
        return data
    if "gzip" in encoding or "zlib" in encoding:
        return zlib.decompress(data)
    if "bzip2" in encoding:
        return bz2.decompress(data)
    if "xz" in encoding or "lzma" in encoding:
        return lzma.decompress(data)
    raise ValueError("unsupported encoding " + encoding)


def walk(elem, prefix, heap, outdir):
    for f in elem.findall("file"):
        name = f.findtext("name")
        if not name or name in (".", "..") or "/" in name:
            raise ValueError("unsafe entry name %r" % name)
        rel = os.path.join(prefix, name)
        path = os.path.join(outdir, rel)
        kind = f.findtext("type")
        if kind == "directory":
            os.makedirs(path, exist_ok=True)
            walk(f, rel, heap, outdir)
        elif kind == "file":
            d = f.find("data")
            off = int(d.findtext("offset"))
            length = int(d.findtext("length"))
            enc = d.find("encoding")
            raw = heap[off:off + length]
            out = decode(raw, enc.get("style") if enc is not None else None)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "wb") as fh:
                fh.write(out)
            print("%10d  %s" % (len(out), rel))


def main():
    src, outdir = sys.argv[1], sys.argv[2]
    with open(src, "rb") as fh:
        blob = fh.read()
    magic, hsize, _ver, toc_c, _toc_u, _alg = struct.unpack(">4sHHQQI", blob[:28])
    if magic != b"xar!":
        sys.exit("not a xar archive")
    toc = zlib.decompress(blob[hsize:hsize + toc_c])
    heap = memoryview(blob)[hsize + toc_c:]
    root = ET.fromstring(toc).find("toc")
    os.makedirs(outdir, exist_ok=True)
    walk(root, "", heap, outdir)


if __name__ == "__main__":
    main()
