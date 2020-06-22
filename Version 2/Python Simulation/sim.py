import numpy
import sys
import random

class memPopulate:
    """ 
    Contains the SRAM and functions used to initialize the SRAM with a binary given state
    populate function takes a 5*5*64 state as input and returns a 200*8 SRAM with lanes interleaved except Lane(0,0)
    """
    def __init__(self):
        self.sram = numpy.zeros(shape=(200,8), dtype = int)     #SRAM
        self.A = numpy.zeros(shape=(5,5,64), dtype=int)         #State

    def StringToState(self, strinp):
        """
        Take an ASCII string as input and convert it to a SHA-3 state
        """
        res = ''.join(format(ord(i), 'b') for i in strinp) 
        if (len(res) > 1088):
            print("String too long for current version", end='\n')
            sys.exit()
        while(len(res)%8):   #Prefix 0s until message can be organized into bytes
            res = '0'+res
        res = res + '00000110'      #Pad 0x06
        while(len(res) != 1592):
            res = res + '00000000'
        res = res + '10000000'      #End padding with 0x80
        if (len(res) != 1600):
            print("Failed to pad string", end='\n')
            sys.exit()
        for x in range(5):
            for y in range(5):
                for z in range(64):
                    #self.A[x][y][z] = res[64*(5*y+x)+z]     #Initialize state
                    #self.A[x][y][z] = z
                    self.A[x][y][z] = 10*x+y
                    #self.A[x][y][z] = random.randint(0,1)
        return self.A

    def interleave(self, A, B, temp):       
        """
        Interleave lanes to store in SRAM
        """
        for i in range(64):
            temp.append(int(A[i]))
            temp.append(int(B[i]))
        return temp

    def StateToMem(self, A):                
        """
        Store a state to SRAM using interleaved mode of storage
        """
        temp = []
        for i in range(64):
            temp.append(int(A[0][0][i]))
        i = 0
        j = 1
        while(1):
            if (j+1 >= 5):
                if (i+1 >= 5):
                    break
                else:
                    temp = self.interleave(A[i][j], A[i+1][(j+1)%5], temp)
            else:
                temp = self.interleave(A[i][j],A[i][j+1], temp)
            j = j+2
            if (j >= 5):
                j = j%5
                i = i+1
            if (i >= 5):
                break
        if (len(temp) != 1600):
            print("Failed to interleave memory", end='\n')
            sys.exit()
        for i in range(200):
            for j in range(8):
                self.sram[i][j] = temp[i*8+j]
        return self.sram

    def populate(self, A):                  
        """
        Handler function to populate SRAM
        """
        return self.StateToMem(self.StringToState(A))

class Register:
    """
    Contains the 64 bit registers and functions to save and extract slice pairs and lanes to/from the SRAM 
    """
    def __init__(self):
        self.R = numpy.zeros(shape=(64,), dtype=int)   #One 64 bit register

    def loadSliceBlock(self, i, sram):
        """
        Load a block of 2 consecutive slices from SRAM to register (50 bits)
        """
        if (i > 31):
            print("Slice pair out of bounds")
            sys.exit()

        #Load from non-interleaved word
        self.R[0] = sram[int(i/4)][2*(i%4)]
        self.R[1] = sram[int(i/4)][2*(i%4)+1]

        #Load from interleaved words
        pos = 2
        if not i%2:
            for j in range(23-(15-int(i/2)), 200-(15-int(i/2)), 16):
                for k in range(0, 4):
                    self.R[pos] = sram[j][k]
                    pos += 1
        else:
            for j in range(23-(15-int(i/2)), 200-(15-int(i/2)), 16):
                for k in range(4, 8):
                    self.R[pos] = sram[j][k]
                    pos += 1

    def saveSliceBlock(self, i, sram):
        """
        Save a block of 2 consecutive slices to SRAM from register (50 bits)
        """
        if (i > 31):
            print("Slice pair out of bounds")
            sys.exit()

        #Save to non-interleaved word
        sram[int(i/4)][2*(i%4)] = self.R[0]
        sram[int(i/4)][2*(i%4)+1] = self.R[1]

        #Save to interleaved words
        pos = 2
        if not i%2:
            for j in range(23-(15-int(i/2)), 200-(15-int(i/2)), 16):
                for k in range(0, 4):
                    sram[j][k] = self.R[pos]
                    pos += 1
        else:
            for j in range(23-(15-int(i/2)), 200-(15-int(i/2)), 16):
                for k in range(4, 8):
                    sram[j][k] = self.R[pos]
                    pos += 1

    def loadLane(self, b, sram):
        """
        Load a Lane from SRAM to register (64 bits bits)
        """
        if (b > 24):
            print("Lane index out of bounds")
            sys.exit()

        # Load lane from non-interleaved memory
        if b==0:
            for i in range(8):
                for j in range(8):
                    self.R[i*8+j] = sram[i][j]

        # Load lane from interleaved memory
        else:
            pos = 0
            offset = 8 + (int((b+1)/2)-1)*16
            for i in range(offset, offset+16):
                if b%2:
                    for j in range(4):
                        self.R[pos] = sram[i][2*j]
                        pos += 1
                else:
                    for j in range(4):
                        self.R[pos] = sram[i][2*j+1]
                        pos += 1

    def MemToState(self, sram):
        """
        Convert a 200*8 block of SRAM to a 5*5*64 state for printing the result
        """
        A = numpy.zeros(shape=(5,5,64), dtype=int)
        for i in range(13):
            self.loadLanePair(i, sram)
            if i == 0:
                for z in range(64):
                    A[0][0][z] = self.R[0][z]
            else:
                x1 = int((2*i-1)/5)
                y1 = (2*i-1)%5
                x2 = int((2*i)/5)
                y2 = (2*i)%5
                for z in range(64):
                    A[x1][y1][z] = self.R[0][z]
                    A[x2][y2][z] = self.R[1][z]
        return A

    def cleanRam(self, sram):
        """
        Erases contents of SRAM
        """
        for i in range(200):
            for j in range(8):
                sram[i][j] = 0
        

class SHA3:
    """
    Class for calling lanewise and slicewise operations and implement overall algorithm
    """
    def __init__(self):
        self.nothing = 0

    def test(self):

        P = memPopulate()
        R = Register()

        P.sram = P.populate(str(input("Enter String - ")))

        # for i in range(200):
        #     for j in range(8):
        #         print("%d"%P.sram[i][j], end=' ')
        #     print("")

        R.loadLane(0, P.sram)

        for i in range(63, -1, -1):
            print("%2d"%R.R[i], end=' ')
        print('')

def main():

    sha = SHA3()
    sha.test()

if __name__ == '__main__':
    main()