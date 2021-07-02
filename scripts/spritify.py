#
# Generate Screens.jack and Sprites.jack files 
#

import sys
import subprocess
import os
from os import path
import glob
from PIL import Image
import itertools

aseprite_path = '/Users/dchristianson/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS'
explicit_zero = False

def chunker(iterable, n):
    args = [iter(iterable)] * n
    return itertools.zip_longest(*args)

def aseprite_save_as(input, output):
    print(f'converting: {input} -> {output}')
    out = subprocess.run([f'{aseprite_path}/aseprite', '-b', input, '--save-as', output])
    out.check_returncode()


def is_black(pixel):
    return (sum(pixel[0:2]) / 3.0) < 128 and (len(pixel) < 4 or pixel[3] < 10)

def bit(pixel):
    return 0 if is_black(pixel) else 1

def bits2int(bits):
    return int(''.join([str(bit) for bit in bits]), 2)

def int2asm(i):
    return '$' + hex(i)[2:]

def anybits(bits):
    return 1 if sum(bits) > 0 else 0

def reduce_bits(bits, n):
    return [anybits(chunk) for chunk in chunker(bits, n)]

def complement(n, b):
    if n >= 0:
        return n
    return b + n

def hmove(n):
    return complement(-n, b=16) * 16

# compress an array of bits to a single byte at single, double or quad resolution
def compress8(bits):
    start_index = len(bits) - 1
    end_index = 0
    for i, b in enumerate(bits):
        if 0 == b:
            continue
        if i < start_index:
            start_index = i
        if i > end_index:
            end_index = i
    bit_length = end_index - start_index    
    if (bit_length <= 8):
        #start_index = max(0, end_index - 7)
        end_bits = min(len(bits), start_index + 8)
        bits = bits[start_index:end_bits]
        pad = 8 - len(bits)
        bits = bits + ((0,) * pad)
        return (0, start_index, bits2int(bits))
    if (bit_length <= 16):
        #start_index = max(0, end_index - 15)
        end_bits = min(len(bits), start_index + 16)
        bits = bits[start_index:end_bits]
        pad = 16 - len(bits)
        bits = bits + ((0,) * pad)
        return (5, start_index, bits2int(reduce_bits(bits, 2)))
    #start_index = max(0, end_index - 31)
    end_bits = min(len(bits), start_index + 32)
    bits = bits[start_index:end_bits]
    pad = 32 - len(bits)
    bits = bits + ((0,) * pad)
    return (7, start_index, bits2int(reduce_bits(bits, 4)))

def shift_word(word, offset):
    if offset < 0:        
        mask = (1 << (-offset)) - 1
    else:
        nbits = len(word)
        mask = ((1 << nbits) - 1) - ((1 << (nbits - offset)) - 1)
    if word & mask:
        raise Exception()
    if offset < 0:
        return word >> (-offset)
    else:
        return word << offset

def solve_for_hmove(tuples):
    # find offsets
    vars = [[], [], []]
    for i in range(0, len(tuples) - 1):
        if tuples[i + 1][2] == 0:
            delta_offset = 0
        else:
            delta_offset = tuples[i + 1][1] - tuples[i][1]
        vars[0].append(tuples[i][0])
        vars[1].append(delta_offset)
        vars[2].append(tuples[i][2])
    vars[0].append(tuples[-1][0])
    vars[1].append(0)
    vars[2].append(tuples[-1][2])
    print(vars[1])
    # convert to hmove
    vars[1] = list([hmove(var) for var in vars[1]])
    return vars



# variable resolution sprite
def emit_sprite8(varname, image, fp, width=24, reverse=False):
    if not image.mode == 'RGBA':
        image = image.convert(mode='RGBA')
    data = image.getdata()
    rows = chunker(map(bit, data), width)
    if reverse:
        rows = [tuple(reversed(row)) for row in rows]
    tuples = list([compress8(row) for row in rows])
    vars = solve_for_hmove(tuples)
    # write output
    for col in vars:
        value = ','.join([int2asm(word) for word in reversed(col)])
        fp.write(f'\t\t\t\tbyte\t{value}; {len(col)}\n')

# full sized sprite
def emit_sprite24(varname, image, fp):
    if not image.mode == 'RGBA':
        image = image.convert(mode='RGBA')
    data = image.getdata()
    vars = [[], [], []]
    for i, word in enumerate([bits2int(chunk) for chunk in chunker(map(bit, data), 8)]):
        vars[i % 3].append(word)
    for col in vars:
        value = ','.join([int2asm(word) for word in reversed(col)])
        fp.write(f'\t\t\t\tbyte\t{value}; {len(col)}\n')


if __name__ == "__main__":

    sprites = {}
    for filename in sys.argv[1:]:
        spritename, ext = os.path.splitext(path.basename(filename))
        aseprite_save_as(filename, f'data/{spritename}_001.png')
        sprites[spritename] = list(glob.glob(f'data/{spritename}_*.png'))

    out = sys.stdout
    for spritename, files in sprites.items():
        # 24 bit
        for i, filename in enumerate(files):
            varname = f'{spritename}.{i}'
            with Image.open(filename, 'r') as image:
                emit_sprite24(varname, image, out)
        # 8 bit
        for i, filename in enumerate(files):
            varname = f'{spritename}.{i}'
            with Image.open(filename, 'r') as image:
                emit_sprite8(varname, image, out)
                emit_sprite8(varname, image, out, reverse=True)


        
