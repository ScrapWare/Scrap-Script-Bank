#!/usr/bin/python

import os
import sys
import re

from struct import pack, unpack, calcsize, iter_unpack

pngh = b"\x89\x50\x4e\x47\x0d\x0a\x1a\x0a"
ihdr = b"\x00\x00\x00\x0d\x49\x48\x44\x52"

emes = ''

def read_exif(f) -> dict:

  e = {}
  t = ''
  w = 0
  h = 0
  d = 0
  p = ''
  s = 0

  try:
    fh = open(f ,"rb")
  except Exception as e:
    emes = e
    return {}
  # PNG Header
  t = fh.read(8)
  if(t != pngh):
    fh.close()
    emes = 'Invalid PNG Signature'
    return {}
  # IHDR Chunk
  t = fh.read(8)
  if(t != ihdr):
    fh.close()
    emes = 'Invalid IHDR'
    return {}

  e['PNG'] = 1

  # Width
  t = fh.read(4)
  e['width'] = int.from_bytes(t)
  # Height
  t = fh.read(4)
  e['height'] = int.from_bytes(t)
  # Pixel Depth
  t = fh.read(1)
  e['depth'] = int.from_bytes(t)
  # Color Type
  t = fh.read(1)
  e['color'] = int.from_bytes(t)
  # Compression Method
  t = fh.read(1)
  e['compression'] = int.from_bytes(t)
  # Filter Type
  t = fh.read(1)
  e['filter'] = int.from_bytes(t)
  # Interlace
  t = fh.read(1)
  e['interlace'] = int.from_bytes(t)
  # CRC
  t = fh.read(4)
  e['CRC'] = int.from_bytes(t)

  e['parameters_Pos'] = fh.tell()

  # getChunkSize()
  t = fh.read(4)
  s = int.from_bytes(t)
  # Size of parameters
  e['parameters_Size'] = s;

  # check tEXt(when iTXt on Meitu)
  t = fh.read(4)
  if(t != b'tEXt' and t != b'iTXt'):
    fh.close()
    emes = 'tEXt: Nothing tEXt chunk!('+t.decode('utf-8')+')'
    return {}

  # parameters
  p = fh.read(s)
  e['parameters'] = p.decode('utf-8')

  if(re.match('parameters', p.decode('utf-8')) == None):
    fh.close()
    emes = 'tEXt: Not a Stable Diffusion Parameters!'
    return {}

  # CRC
  t = fh.read(4)
  e['tEXt_CRC'] = t

  fh.close()

  if(len(e) == 0):
    return {}

  return e

# Like simple `mogrify -strip "$n"` for @ARGV, not same `cmp -b A B`; from mogrify results;;;

def main(argv):

  for f in argv:

    if(re.search("\.(jpe?g|png)$", f) and os.path.isfile(f)):

      r = read_exif(f)

      if(emes):
        print(emes)
        exit()
      if(len(r) == 0):
        print('Not Length: '+f+"\n")
        continue
      if('parameters' not in r):
        print('Not Params: '+f+"\n")
        continue

      n = re.sub('\.(jpe?g|png)$', '.noexif.\\1', f, 1)

      print(f+" -> "+n+"\n")

      print(r['parameters']+"\n")

      s = r['parameters_Size']+12

      ifh = open(f, "rb")
      png = ifh.read(33)
      ifh.seek(s, os.SEEK_CUR)
      png += ifh.read()
      ifh.close()

      ofh = open(n, "wb")
      ofh.write(png)
      ofh.close()

if __name__ == "__main__":
  argn = sys.argv
  argn.pop(0)
  main(argn)
