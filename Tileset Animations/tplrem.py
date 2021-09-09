import struct
import sys

version = '1.0'

def main():
    # read input
    if '-v' in sys.argv:
        print("%s v%s" % (sys.argv[0], version))
        return

    if '-h' in sys.argv or len(sys.argv) < 2:
        print('usage: %s -v | -h | infile [outfile]' % sys.argv[0])
        return

    input = str(sys.argv[1])
    if len(sys.argv) == 2:
        output = input + '.noheader'
    else:
        output = str(sys.argv[2])

    # read input
    print("reading '%s'" % input)
    with open(input, 'rb') as f:
        in_ = bytearray(f.read())

    # skip through headers to find start of pix data
    print("processing...")
    off1 = int(struct.unpack('>8xI', in_[:12])[0])
    off2 = int(struct.unpack('>I', in_[off1:off1+4])[0])
    off3 = int(struct.unpack('>8xI', in_[off2:off2+12])[0])

    # slice the headers off
    out = in_[off3:]

    # write output
    print("writing to '%s'" % output)
    with open(output, 'wb') as f:
        f.write(out)

main()