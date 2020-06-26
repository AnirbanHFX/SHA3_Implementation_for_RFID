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
                    self.A[x][y][z] = res[64*(5*y+x)+z]     #Initialize state
                    #self.A[x][y][z] = z
                    #self.A[x][y][z] = 10*x+y
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
    Contains the 2 64 bit registers and functions to save and extract slice blocks and lane pairs to/from the SRAM 
    """
    def __init__(self):
        self.R = numpy.zeros(shape=(2,64), dtype=int)   #Two 64 bit registers

    def loadSliceBlock(self, i, sram):
        """
        Load a block of 4 consecutive slices from SRAM to register (100 bits)
        """
        if (i > 15):
            print("Slice block out of bounds")
            sys.exit()
        interleavedword = 23-(15-i)
        maxword = 200-(15-i)
        noninterleavedword = [int(i/2), int((i%2)*4)]
        i = noninterleavedword[0]
        j = noninterleavedword[1]
        pos = 0
        for j in range(noninterleavedword[1],noninterleavedword[1]+4,2):
            self.R[0][pos] = sram[i][j]
            self.R[1][pos] = sram[i][j+1]
            pos = pos + 1
        i = interleavedword
        j = 0
        for i in range(interleavedword, maxword, 16):
            for j in range(0, 8, 2):
                self.R[0][pos] = sram[i][j]
                self.R[1][pos] = sram[i][j+1]
                pos = pos + 1

    def saveSliceBlock(self, i, sram):
        """
        Save a block of 4 consecutive slices from register to SRAM(100 bits)
        """
        if (i > 15):
            print("Slice block out of bounds")
            sys.exit()
        interleavedword = 23-(15-i)
        maxword = 200-(15-i)
        noninterleavedword = [int(i/2), int((i%2)*4)]
        i = noninterleavedword[0]
        j = noninterleavedword[1]
        pos = 0
        for j in range(noninterleavedword[1], noninterleavedword[1]+4,2):
            sram[i][j] = self.R[0][pos]
            sram[i][j+1] = self.R[1][pos]
            pos = pos + 1
        i = interleavedword
        j = 0
        for i in range(interleavedword, maxword, 16):
            for j in range(0, 8, 2):
                sram[i][j] = self.R[0][pos]
                sram[i][j+1] = self.R[1][pos]
                pos = pos + 1
    
    def loadLanePair(self, b, sram):
        """
        Load two consecutive lanes from SRAM to register (128 bits)
        If Lane(0,0) is loaded, then only register 0 is filled (64 bits)
        """
        if b==0:
            for i in range(8):
                for j in range(8):
                    self.R[0][i*8+j] = sram[i][j]
        elif b < 13:
            offset = 8 + (b-1)*16
            for i in range(offset, offset+16):
                for j in range(4):
                    self.R[0][(i-offset)*4+j] = sram[i][2*j]
                    self.R[1][(i-offset)*4+j] = sram[i][2*j+1]
        else:
            print("Lane pair out of bounds")
            sys.exit()

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
    
class SliceProcessor:
    
    """
    Contains functions that simulate slice wise operations using given datapath and constraints
    """

    def __init__(self):
        self.ParityReg = numpy.zeros(shape=(5,), dtype=int)     #Parity register used for Theta step
        self.tempParityReg = numpy.zeros(shape=(5,), dtype=int)
        self.x = numpy.zeros(shape=(5,5,2), dtype=int)          #Contains indices of slices in the registers when a slice is loaded
        self.curslice = -1                                      #Index of current slice block in registers
        self.temp = numpy.zeros(shape=(5,5), dtype=int)         #Temporary array used for updating slices sequentially in the simulation (will not be required during parallel updates in hardware)
        self.RC = [ "0000000000000000000000000000000000000000000000000000000000000001",
                    "0000000000000000000000000000000000000000000000001000000010000010",
                    "1000000000000000000000000000000000000000000000001000000010001010",
                    "1000000000000000000000000000000010000000000000001000000000000000",
                    "0000000000000000000000000000000000000000000000001000000010001011",
                    "0000000000000000000000000000000010000000000000000000000000000001",
                    "1000000000000000000000000000000010000000000000001000000010000001",
                    "1000000000000000000000000000000000000000000000001000000000001001",
                    "0000000000000000000000000000000000000000000000000000000010001010",
                    "0000000000000000000000000000000000000000000000000000000010001000",
                    "0000000000000000000000000000000010000000000000001000000000001001",
                    "0000000000000000000000000000000010000000000000000000000000001010",
                    "0000000000000000000000000000000010000000000000001000000010001011",
                    "1000000000000000000000000000000000000000000000000000000010001011",
                    "1000000000000000000000000000000000000000000000001000000010001001",
                    "1000000000000000000000000000000000000000000000001000000000000011",
                    "1000000000000000000000000000000000000000000000001000000000000010",
                    "1000000000000000000000000000000000000000000000000000000010000000",
                    "0000000000000000000000000000000000000000000000001000000000001010",
                    "1000000000000000000000000000000010000000000000000000000000001010",
                    "1000000000000000000000000000000010000000000000001000000010000001",
                    "1000000000000000000000000000000000000000000000001000000010000000",
                    "0000000000000000000000000000000010000000000000000000000000000001",
                    "1000000000000000000000000000000010000000000000001000000000001000" ]    
                    #Round constants for Iota stage

    def extractslice(self, pos):
        """
        Function to calculate the indices of a given slice when loaded into the registers
        This function can be omitted for hardware implementation since its returned values are pre-determined
        The indices of a given slice are stored in self.x
        The (x,y) element of a slice can be accessed from a register as - R[self.x[x][y][0]][self.x[x][y][1]], where R[2][64] is a 2*64 array which refers to the 2 64 bit registers 
        """
        if pos%4 == 0:
            self.x[0][0] = [0, 0]
            self.x[0][1] = [0, 2]
            i = 0
            j = 2
            toggle = 1
            offset = 2
            while i<5:
                while j<5:
                    self.x[i][j] = [toggle, offset]
                    if toggle == 1:
                        offset = offset + 4
                    toggle = not toggle
                    j = j+1
                j = 0
                i = i+1
        elif pos%4 == 1:
            self.x[0][0] = [1, 0]
            i = 0
            j = 1
            toggle = 0
            offset = 3
            while i<5:
                while j<5:
                    self.x[i][j] = [toggle, offset]
                    if toggle == 1:
                        offset = offset + 4
                    toggle = not toggle
                    j = j+1
                j = 0
                i = i+1
        elif pos%4 == 2:
            self.x[0][0] = [0, 1]
            i = 0
            j = 1
            toggle = 0
            offset = 4
            while i<5:
                while j<5:
                    self.x[i][j] = [toggle, offset]
                    if toggle == 1:
                        offset = offset + 4
                    toggle = not toggle
                    j = j+1
                j = 0
                i = i+1
        else:
            self.x[0][0] = [1, 1]
            i = 0
            j = 1
            toggle = 0
            offset = 5
            while i<5:
                while j<5:
                    self.x[i][j] = [toggle, offset]
                    if toggle == 1:
                        offset = offset + 4
                    toggle = not toggle
                    j = j+1
                j = 0
                i = i+1
        
    def storeParity(self, R, nslice):
        """
        Calculates column parities of given slice and stores it in the parity register
        """
        if (self.curslice != nslice):
            self.extractslice(nslice)
            self.curslice = nslice
        for x in range(5):
            self.tempParityReg[x] = self.ParityReg[x]
        for x in range(5):
            self.ParityReg[x] = 0
            for y in range(5):
                self.ParityReg[x] = self.ParityReg[x] ^ R[self.x[x][y][0]][self.x[x][y][1]]

    def theta(self, R, nslice):
        """
        Slice wise Theta stage implementation
        """
        if (self.curslice != nslice):
            self.extractslice(nslice)
            self.curslice = nslice
        for x in range(5):
                self.tempParityReg[x] = self.tempParityReg[x]^(R[self.x[(x-2)%5][0][0]][self.x[(x-2)%5][0][1]] ^ R[self.x[(x-2)%5][1][0]][self.x[(x-2)%5][1][1]] ^ R[self.x[(x-2)%5][2][0]][self.x[(x-2)%5][2][1]] ^ R[self.x[(x-2)%5][3][0]][self.x[(x-2)%5][3][1]] ^ R[self.x[(x-2)%5][4][0]][self.x[(x-2)%5][4][1]])
        for x in range(5):
            for y in range(5):
                R[self.x[(x-1)%5][y][0]][self.x[(x-1)%5][y][1]] = self.tempParityReg[x] ^ R[self.x[(x-1)%5][y][0]][self.x[(x-1)%5][y][1]]

    def pi(self, R, nslice):
        """
        Slice wise Pi stage implementation
        """
        if (self.curslice != nslice):
            self.extractslice(nslice)
            self.curslice = nslice
        for x in range(5):
            for y in range(5):
                self.temp[x][y] = R[self.x[(x+3*y)%5][x][0]][self.x[(x+3*y)%5][x][1]]
        for x in range(5):
            for y in range(5):
                R[self.x[x][y][0]][self.x[x][y][1]] = self.temp[x][y]  

    def chi(self, R, nslice):
        """
        Slice wise Chi stage implementation
        """
        if (self.curslice != nslice):
            self.extractslice(nslice)
            self.curslice = nslice
        for x in range(5):
            for y in range(5):
                self.temp[x][y] = R[self.x[x][y][0]][self.x[x][y][1]] ^ ((R[self.x[(x+1)%5][y][0]][self.x[(x+1)%5][y][1]] ^ 1) & R[self.x[(x+2)%5][y][0]][self.x[(x+2)%5][y][1]])
        for x in range(5):
            for y in range(5):
                R[self.x[x][y][0]][self.x[x][y][1]] = self.temp[x][y]

    def iota(self, R, nslice, rnd):
        """
        Slice wise Iota stage implementation
        """
        if (self.curslice != nslice):
            self.extractslice(nslice)
            self.curslice = nslice
        R[self.x[0][0][0]][self.x[0][0][1]] = R[self.x[0][0][0]][self.x[0][0][1]] ^ int(self.RC[rnd][64-nslice-1])

class LaneProcessor:

    """
    Contains functions that simulate lane wise operations for the given datapath and constraints
    """

    def __init__(self):
        self.rotc = [1, 3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14,
		             27, 41, 56, 8, 25, 43, 62, 18, 39, 61, 20, 44 ]
                     #Keccak rotation offsets
        self.rhounit = numpy.zeros(shape=(2,4), dtype=int)

    def shift_array_left(self, array, bits, size):
        """
        Simulates left shifting of an array using a Barrel Shifter
        """
        newarray = numpy.zeros(shape=(size,), dtype=int)
        for i in range(size):
            if (bits+i < size):
                newarray[i] = array[bits+i]
            else:
                break
        return newarray

    def shift_array_right(self, array, bits, size):
        """
        Simulates right shifting of an array using a Barrel Shifter
        """
        newarray = numpy.zeros(shape=(size,), dtype=int)
        for i in range(size-1, -1, -1):
            if(i-bits >= 0):
                newarray[i] = array[i-bits]
            else:
                break
        return newarray

    def xor_arrays(self, array1, array2):
        """
        XOR two arrays
        """
        sizemax = len(array1)
        if len(array2) > sizemax:
            sizemax = len(array2)
        newarray = numpy.zeros(shape=(sizemax,), dtype=int)
        for i in range(sizemax):
            if i<len(array1) and i<len(array2):
                newarray[i] = array1[i] ^ array2[i]
            elif i<len(array1):
                newarray[i] = array1[i]
            else:
                newarray[i] = array2[i]
        return newarray

    def rho(self, R, lanepair, sram):
        """
        Applies Rho stage on two consecutive lanes
        Lane(0,0) is omitted since it requires no rotation
        """
        if (lanepair > 0):
            offset = 8 + (lanepair-1)*16            # Offset points to initial SRAM address
            rot1 = self.rotc[2*(lanepair-1)]        # Rotation constant for first lane
            rot1lowerbits = rot1%4                  # Extract lower 2 bits of rotation constant for first lane (fed to Barrel Shifter)
            rot1upperbits = int(rot1/4)             # Extract upper 4 bits of rotation constant for first lane (for register addressing)
            rot2 = self.rotc[2*(lanepair-1)+1]      # Rotation constant for second lane
            rot2lowerbits = rot2%4                  # Extract lower 2 bits of rotation constant for second lane (fed to Barrel Shifter)
            rot2upperbits = int(rot2/4)             # Extract upper 4 bits of rotation constant for second lane (for register addressing)

            temp00 = numpy.zeros(shape=(4,), dtype=int)     # Temporary arrays for simulating Barrel Shifter (not required for hardware implementation)
            temp01 = numpy.zeros(shape=(4,), dtype=int)
            temp10 = numpy.zeros(shape=(4,), dtype=int)
            temp11 = numpy.zeros(shape=(4,), dtype=int)

            for r in range(16):                     # Iterate through all 16 register sections
            
                for i in range(4):                  # Read register section
                    temp00[i] = R[0][4*rot1upperbits+i]
                    temp01[i] = R[1][4*rot2upperbits+i]   
                temp00 = self.shift_array_left(temp00, rot1lowerbits, 4)    # Shift left using Barrel Shifter
                temp01 = self.shift_array_left(temp01, rot2lowerbits, 4)
                self.rhounit[0] = self.xor_arrays(temp00, [0])              # XOR shifted data in Rho Unit register
                self.rhounit[1] = self.xor_arrays(temp01, [0])
                if len(self.rhounit[0]) != 4 or len(self.rhounit[1]) != 4:
                    print("Rho Units corrupted during left shift")
                    sys.exit()

                for i in range(4):                  # Read next register section
                    temp10[i] = R[0][4*((rot1upperbits+1)%16)+i]
                    temp11[i] = R[1][4*((rot2upperbits+1)%16)+i]
                temp10 = self.shift_array_right(temp10, 4-rot1lowerbits, 4) # Shift right using Barrel Shifter
                temp11 = self.shift_array_right(temp11, 4-rot2lowerbits, 4)
                self.rhounit[0] = self.xor_arrays(self.rhounit[0], temp10)  # XOR shifter data in Rho Unit registers
                self.rhounit[1] = self.xor_arrays(self.rhounit[1], temp11)
                if len(self.rhounit[0]) != 4 or len(self.rhounit[1]) != 4:
                    print("Rho Units corrupted during right shift")
                    sys.exit()

                for i in range(4):                  # Interleave contents of Rho Unit registers and save to appropriate SRAM address
                    sram[offset+r][2*i] = self.rhounit[0][i]
                    sram[offset+r][2*i+1] = self.rhounit[1][i]

                rot1upperbits = (rot1upperbits+1)%16       # Increment register addresses
                rot2upperbits = (rot2upperbits+1)%16

class referenceImplementation:

    """
    Reference SHA-3 implementation to test output
    """

    def __init__(self, state):
        self.A = numpy.zeros(shape=(5,5,64), dtype=int)
        self.B = numpy.zeros(shape=(5,5,64), dtype=int)
        for i in range(5):
            for j in range(5):
                for k in range(64):
                    self.A[i][j][k] = state[i][j][k]
        self.rotc = [0, 1, 3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14,
		             27, 41, 56, 8, 25, 43, 62, 18, 39, 61, 20, 44 ]
        self.RC = [ "0000000000000000000000000000000000000000000000000000000000000001",
                    "0000000000000000000000000000000000000000000000001000000010000010",
                    "1000000000000000000000000000000000000000000000001000000010001010",
                    "1000000000000000000000000000000010000000000000001000000000000000",
                    "0000000000000000000000000000000000000000000000001000000010001011",
                    "0000000000000000000000000000000010000000000000000000000000000001",
                    "1000000000000000000000000000000010000000000000001000000010000001",
                    "1000000000000000000000000000000000000000000000001000000000001001",
                    "0000000000000000000000000000000000000000000000000000000010001010",
                    "0000000000000000000000000000000000000000000000000000000010001000",
                    "0000000000000000000000000000000010000000000000001000000000001001",
                    "0000000000000000000000000000000010000000000000000000000000001010",
                    "0000000000000000000000000000000010000000000000001000000010001011",
                    "1000000000000000000000000000000000000000000000000000000010001011",
                    "1000000000000000000000000000000000000000000000001000000010001001",
                    "1000000000000000000000000000000000000000000000001000000000000011",
                    "1000000000000000000000000000000000000000000000001000000000000010",
                    "1000000000000000000000000000000000000000000000000000000010000000",
                    "0000000000000000000000000000000000000000000000001000000000001010",
                    "1000000000000000000000000000000010000000000000000000000000001010",
                    "1000000000000000000000000000000010000000000000001000000010000001",
                    "1000000000000000000000000000000000000000000000001000000010000000",
                    "0000000000000000000000000000000010000000000000000000000000000001",
                    "1000000000000000000000000000000010000000000000001000000000001000" ]

    def theta(self):
        C = numpy.zeros(shape=(5, 64), dtype=int)
        D = numpy.zeros(shape=(5, 64), dtype=int)
        for z in range(64):
            for x in range(5):
                C[x][z] = self.A[x][0][z] ^ self.A[x][1][z] ^ self.A[x][2][z] ^ self.A[x][3][z] ^ self.A[x][4][z]
        for z in range(64): 
            for x in range(5):
                D[x][z] = C[(x-1)%5][z] ^ C[(x+1)%5][(z-1)%64]
        for z in range(64):
            for x in range(5):
                for y in range(5):
                    self.A[x][y][z] = self.A[x][y][z] ^ D[x][z]
    
    def rhopi(self):
        for x in range(5):
            for y in range(5):
                self.B[y][(2*x+3*y)%5] = numpy.roll(self.A[x][y], 64-self.rotc[5*x+y])

    def chi(self, z):
        for x in range(5):
            for y in range(5):
                    self.A[x][y][z] = self.B[x][y][z] ^ ((~self.B[(x+1)%5][y][z]) & self.B[(x+2)%5][y][z])

    def iota(self, z, rnd):
        self.A[0][0][z] = self.A[0][0][z] ^ int(self.RC[rnd][64-z-1])

    def Keccak(self):

        for i in range(24):
            self.theta()
            self.rhopi()
            for z in range(64):
                self.chi(z)
            for z in range(64):
                self.iota(z, i)

class SHA3:

    """
    Class for calling lanewise and slicewise operations and implement overall algorithm
    """

    def __init__(self):
        self.nothing = 0

    def fullTheta(self, P, R, S, L):
        """
        Load slice blocks sequentially and apply Theta stage on entire state
        """
        R.loadSliceBlock(15, P.sram)
        S.storeParity(R.R, 63)
        for i in range(64):
            if (i%4 == 0):
                R.loadSliceBlock(int(i/4), P.sram)
            S.storeParity(R.R, i)
            S.theta(R.R, i)
            if (i%4 == 3):
                R.saveSliceBlock(int(i/4), P.sram)

    def fullrho(self, P, R, S, L):
        """
        Load lane pairs sequentially and apply Rho stage of entire state
        """
        for i in range(1, 13):
            R.loadLanePair(i, P.sram)
            L.rho(R.R, i, P.sram)
            #R.saveLanePair(i, P.sram)

    def miniround(self, P, R, S, L, rnd):
        """
        Modified round
        Apply Pi, Chi and Iota stages on entire state
        """
        for i in range(64):
            if (i%4 == 0):
                R.loadSliceBlock(int(i/4), P.sram)
            S.pi(R.R, i)
            S.chi(R.R, i)
            S.iota(R.R, i, rnd)
            if (i%4 == 3):
                R.saveSliceBlock(int(i/4), P.sram)

    def readExternalRam(self, sram):
        """
        Read SRAM state from external text file
        Used for testing and debugging
        """
        rampt = open("externalram.txt", "r")
        filedata = rampt.readlines()
        rampt.close()
        # filedata = filedata.replace('"',"").strip("(").strip(")").split(",")[0:200]

        if len(filedata) != 200:
            print(len(filedata))
            for line in filedata:
                print(line)
            raise Exception("Incorrect dimensions of filedata")

        for i in range(200):
            for j in range(8):
                sram[i][8-j-1] = int(filedata[i][j])

    def Keccak(self):
        """
        Function to implement overall algorithm, output the final state and compare it to the standard implementation
        """
        P = memPopulate()
        P.sram = P.populate(str(input("Enter String - ")))

        R = Register()
        S = SliceProcessor()
        L = LaneProcessor()

        A = R.MemToState(P.sram)
        for i in range(5):
            for j in range(5):
                for k in range(64):
                    if A[i][j][k] != P.A[i][j][k]:
                        print("Mismatch")
                        sys.exit()

        self.fullTheta(P, R, S, L)
        self.fullrho(P, R, S, L)
        for i in range(23):
            self.miniround(P, R, S, L, i)
            self.fullTheta(P, R, S, L)
            self.fullrho(P, R, S, L)
        self.miniround(P, R, S, L, 23)

        tempram = numpy.zeros(shape=(200, 8), dtype=int)
        for i in range(200):
            for j in range(8):
                tempram[i][j] = P.sram[i][j]

        I = referenceImplementation(P.A)
        I.Keccak()              #Reference implementation
        P.StateToMem(I.A)       #Convert reference implementation output state to SRAM format for comparison

        #Compare contents of SRAM with reference
        for i in range(200):
            for j in range(8):
                if P.sram[i][j] != tempram[i][j]:
                    print("State does not match with reference")
                    sys.exit()

        print("Output state matched with reference")

        A = R.MemToState(tempram)

        print("Output state - ")
        for i in range(5):
            for j in range(5):
                for k in range(64):
                    print(A[i][j][k], end='')
                print("")

    def test(self):

        P = memPopulate()
        #
        # P.sram = P.populate(str(input("Enter String - ")))

        R = Register()
        S = SliceProcessor()
        L = LaneProcessor()

        self.readExternalRam(P.sram)

        # fp = open("debug.txt", "w")
        # for word in P.sram:
        #     for i in range(7,-1,-1):
        #         fp.write("%d"%word[i])
        #     fp.write("\n")
        # fp.close()

        self.fullTheta(P, R, S, L)
        self.fullrho(P, R, S, L)
        for i in range(23):
            self.miniround(P, R, S, L, i)
            self.fullTheta(P, R, S, L)
            self.fullrho(P, R, S, L)
        self.miniround(P, R, S, L, 23)

        for i in range(200):
            print("%d : "%i, end ='')
            for j in range(2):
                aggregate = 0
                for k in range(4):
                    aggregate += int((1<<(3-k))*P.sram[i][7-4*j-k])
                print("%X"%aggregate, end='')
            print('')

def main():
    
    sha = SHA3()

    #sha.test()      # Reads SRAM state from external text file labelled externalram.txt and prints final RAM state

    sha.Keccak()     # SHA3 algorithm simulation

if __name__ == '__main__':

    main()
                