import sys
import PIL.Image as Image

#Outputs a binary file containing Tile data, along with an asm file containing relevant constants.
#This version will assume that everything in the image is the same palette, and in black and white, for the original gameboy.
def maketiles(img : str, outname : str):
    a = Image.open(img)
    binstr = bytearray()
    width, height = a.size
    if width % 8 != 0 or height % 8 != 0:
        print("Image '{}' doesn't contain an integer number of 8x8 tiles.".format(img))
        return
    colours = a.getcolors()
    if len(colours) > 4:
        print("Too many colours. There should be 4 or fewer colours.")
        return
    colours = list(map(lambda x: x[1], colours))
    colours.sort(key=lambda x: x[0]+x[1]+x[2])
    colours = ([colours[0]]*(5-len(colours))) + colours[1:len(colours)] #Fill out the palette so that the lightest colour is white
    for j in [8*x for x in range(width // 8)]:
        for i in [8*x for x in range(height // 8)]:
            currenttile = a.crop((i, j, i + 8, j + 8))
            for t in range(8):
                b1 = ''
                b2 = ''
                for s in range(8):
                    ind = colours.index(currenttile.getpixel((s,t)))
                    b1 += '{}'.format(ind % 2)
                    b2 += '{}'.format(ind // 2)
                binstr.append(int(b1, 2))
                binstr.append(int(b2, 2))
    a.close()
    binfile = open("{}.bin".format(outname), "wb")
    binfile.write(binstr)
    binfile.close()
    asmfile = open("{}.inc".format(outname), 'wb')
    outnameshort = outname
    if '/' in outname:
        outnameshort = outname[outname.rindex('/')+1:len(outname)]
    if '\\' in outnameshort:
        outnameshort = outnameshort[outnameshort.rindex('\\')+1:len(outnameshort)]
    filestring = ";The length in bytes of the tile data in {}.bin is defined here\nDEF {}_LEN EQU {}".format(outnameshort, outnameshort.upper(), len(binstr))
    asmfile.write(bytes(filestring,'utf-8'))
    asmfile.close()



    

if __name__ == "__main__":
    args = sys.argv
    if '--help' in args or '--h' in args:
        print("maketiles.py - A rudimentary tile data generator for the gameboy. Takes in an image (with dimensions divisible by 8) and outputs a tile binary.")
        print("Usage:\n \
              python maketiles.py input [-o output] [--h]\n\
              \t'input' is the input file (format png, jpeg...)\n\
              \t-o output optionally specifies the name of the output files. Defaults to the name of the input, sans extension.\n\
              \t\t-One output is of type bin. This is the raw tile data.\n\
              \t\t-One output is of type inc. This defines the length of the tile data in rgbds assembly.\n\
              \t--h shows this message. Same as '--help'.")
        sys.exit()
    if len(args) < 2:
        print("No input file given.")
        sys.exit(1)
    filename = args[1]
    outname = None
    if '-o' in args:
        ind = args.index('-o')
        if ind == len(args) - 1:
            print("'-o' present, but no output file name specified. Defaulting to input file name.")
        else:
            outname = args[ind + 1]
    if outname == None:
        outname = filename[0:filename.rfind('.')]
    maketiles(filename, outname)