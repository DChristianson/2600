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
from collections import namedtuple
import queue
from dataclasses import dataclass, field

aseprite_path = '/Users/dchristianson/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS'
explicit_zero = False

def pairwise(iterable):
    a, b = itertools.tee(iterable)
    next(b, None)
    return zip(a, b)

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

CompressedBits = namedtuple('CompressedBits', ['scale', 'start_index', 'end_index', 'bits'])

# compress an array of bits to a single byte at single, double or quad resolution
# return tuple of 
def compress8(bits):
    start_index = len(bits)
    end_index = -1
    for i, b in enumerate(bits):
        if 0 == b:
            continue
        if i < start_index:
            start_index = i
        if i > end_index:
            end_index = i
    bits = bits[start_index:end_index + 1]
    bit_length = len(bits)
    if (bit_length <= 8):
        return CompressedBits(1, start_index, end_index, bits)
    if (bit_length <= 16):
        pad = bit_length % 2
        bits = bits + ([0] * pad)
        end_index += pad
        return CompressedBits(2, start_index, end_index, reduce_bits(bits, 2))
    pad = 4 - bit_length % 4
    bits = bits + ([0] * pad)
    end_index += pad
    return CompressedBits(4, start_index, end_index, reduce_bits(bits, 4))

def nusize(i):
    if i == 1:
        return 0
    return i + 3

def paddings(a):
    nbits = len(a.bits)
    pad = 8 - nbits
    for lpad in range(0, pad + 1):
        rpad = pad - lpad
        bits = [0] * lpad + a.bits + [0] * rpad
        start_index = a.start_index - lpad * a.scale
        end_index = a.start_index + 8 * a.scale
        yield start_index, end_index, bits

def is_legal_hmove(i):
    return i < 8 and i > -9

@dataclass(order=True)
class SolutionItem:
    priority: int
    steps: object = field(compare=False)
    frontier: object = field(compare=False)

def find_offset_solution(compressedbits):
    solutions = queue.PriorityQueue()
    base_priority = 10 * (len(compressedbits) - 1)
    for a in paddings(compressedbits[0]):
        solutions.put(SolutionItem(base_priority, [(None, 0, 0, a)], compressedbits[1:]))

    while not solutions.empty():
        item = solutions.get()
        _, _, _, a = item.steps[-1]
        b = item.frontier[0]
        for candidate in paddings(b):
            lmove = candidate[0] - a[0]
            rmove = candidate[1] - a[1]
            if not is_legal_hmove(lmove):# or not is_legal_hmove(rmove):
                continue
            next_step = (a, lmove, rmove, candidate)
            if len(item.frontier) == 1:
                return item.steps[1:] + [next_step]
            else:
                cost = item.priority + abs(lmove) + abs(rmove) - 10
                next_solution = item.steps + [next_step]
                solutions.put(SolutionItem(cost, next_solution, item.frontier[1:]))
            
# variable resolution sprite
def emit_sprite8(varname, image, fp, width=24, reverse=False):
    if not image.mode == 'RGBA':
        image = image.convert(mode='RGBA')
    data = image.getdata()
    rows = chunker(map(bit, data), width)
    if reverse:
        rows = [tuple(reversed(row)) for row in rows]

    compressedbits = list([compress8(list(row)) for row in rows])
    solution = find_offset_solution(compressedbits)

    left_delta = list([step[1] for step in solution])
    right_delta = list([step[2] for step in solution])
    padded_bits = list([step[3][2] for step in solution])

    print(left_delta)
    print(right_delta)
    print(padded_bits)
    
    nusizes = list([ nusize(cb.scale) for cb in compressedbits])
    ctrl = list([hmove(offset) + size for offset, size in zip(left_delta, nusizes)])
    rtrl = list([hmove(-offset) + size for offset, size in zip(right_delta, nusizes)])
    graphics = list([bits2int(bits) for bits in padded_bits])

    # write output
    for col in [ctrl, rtrl, graphics]:
        value = ','.join([int2asm(word) for word in reversed(col)])
        fp.write(f'    byte {value}; {len(col)}\n')

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
                print(';image')
                emit_sprite8(varname, image, out)
                # 
                # print(';reverse')
                # emit_sprite8(varname, image, out, reverse=True)

        
