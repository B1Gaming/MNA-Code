import struct
import sys

def readString(data, pos):
    c = data[pos]
    s = ''

    while c != 0:
        s += chr(c)
        pos += 1
        c = data[pos]

    return s

class AnimTiles:
    def __init__(self, infile_, outfile_):
        self.infile = infile_
        self.outfile = outfile_

    def writeTxt(self):
        with open(self.infile, 'rb') as f:
            bin_ = f.read()

        header = struct.unpack('>4sI', bin_[:8])

        if header[0] != b'NWRa':
            print("Error: invalid .bin file: file magic was not NWRa")

        pos = 8
        self.tiles = []
        for i in range(header[1]):
            # read entry
            entry = struct.unpack('>HHHBB', bin_[pos : pos + 8])
            pos += 8

            # extract name
            name = readString(bin_, entry[0])

            # extract delays
            delays = readString(bin_, entry[1])
            delays = struct.unpack('>' + str(len(delays)) + 'B', bytes(delays, 'ascii'))
            delays = list(map(int, delays))

            # tilenum
            tilenum = int(entry[2])
            tileset = int(entry[3])
            reverse = int(entry[4]) == 1

            self.tiles.append({
                'texname': name,
                'framedelays': delays,
                'tilenum': tilenum,
                'tileset': tileset,
                'reverse': reverse
            })

        # write output file
        properties = ['texname', 'framedelays', 'tilenum', 'tileset', 'reverse']
        out = ""
        for tile in self.tiles:
            for prop in properties:
                if prop == 'reverse':
                    if tile[prop] == True:
                        out += 'reverse = yes\n'
                    continue

                elif prop == 'framedelays':
                    s = ', '.join(map(str, tile[prop]))
                else:
                    s = str(tile[prop])

                out += "%s = %s\n" % (str(prop), s)

            out += '\nend tile\n\n'

        # remove 1 extra newline
        out = out[:-1]

        # write to file
        with open(self.outfile, 'w') as f:
            f.write(out)

    def writeBin(self):
        # read the input and create tiles
        self.readInput()

        # build the bin
        self.encode()

        # write the bin
        with open(self.outfile, 'wb') as f:
            f.write(self.bin)

    def encode(self):
        out = struct.pack('>4sI', b'NWRa', len(self.tiles))

        # first off, calculate a length for the main file
        # so we can build the string table easily
        size = len(out)
        size += len(self.tiles) * 8

        strTable = ''
        strOffset = size + len(strTable)

        # now, write tiles
        for tile in self.tiles:
            # encode the name
            texNameOffset = strOffset

            # there's only room for 56 characters
            name = tile['texname']
            if len(name) > 56:
                name = name[:56]

            strTable += name + '\0'
            strOffset += len(name) + 1

            # encode the delays
            frameDelays = ''
            for delay in tile['framedelays'].split(','):
                frameDelays += chr(int(delay, 0))

            frameDelayOffset = strOffset
            strOffset += len(frameDelays) + 1
            strTable += frameDelays + '\0'

            tileNum = int(tile['tilenum'], 0)
            tilesetNum = int(tile['tileset'], 0)

            if 'reverse' in tile and tile['reverse'] == 'yes':
                reverse = 1
            else:
                reverse = 0

            out += struct.pack('>HHHBB', texNameOffset, frameDelayOffset, tileNum, tilesetNum, reverse)

        # and save the result
        self.bin = out + bytes(strTable, 'ascii')

    def readInput(self):
        # read input
        with open(self.infile, 'r') as f:
            lines = f.readlines()

        # strip whitespace
        proc = []
        for line in lines:
            proc.append(line.strip())

        # self.tiles is an array of dicts
        tiles = []
        currentTile = {}

        # parse the file
        for line in proc:
            if line == 'end tile':
                tiles.append(currentTile)
                currentTile = {}
            elif line != '':
                s = line.split('=', 2)
                name = s[0].strip()
                val = s[1].strip()

                currentTile[name] = val

        self.tiles = tiles

def main():
    if len(sys.argv) < 3:
        printHelp()
        return

    if '-e' not in sys.argv and '-d' not in sys.argv:
        printHelp()
        return

    if '-e' in sys.argv:
        encode = True
        encodeidx = sys.argv.index('-e')
        sys.argv.pop(encodeidx)
    else:
        encode = False
        decodeidx = sys.argv.index('-d')
        sys.argv.pop(decodeidx)

    infile = sys.argv[1]

    if len(sys.argv) == 2:
        fn = ''.join(infile.split('.')[:-1])

        if encode:
            outfile = fn + '.bin'
        else:
            outfile = fn + '.txt'
    else:
        outfile = sys.argv[2]

    anm = AnimTiles(infile, outfile)

    if encode:
        anm.writeBin()
    else:
        anm.writeTxt()

def printHelp():
    print('usage: %s -ed infile [outfile]' % sys.argv[0])
    print('arguments:')
    print('  -e        converts from txt to bin')
    print('  -d        converts from bin to txt')
    print('  infile    the input filename')
    print('  outfile   the output filename (optional)')

if __name__ == '__main__':
    main()
