import numpy
import sys
import random
import math

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
        for i in range(5):
            for j in range(5):
                self.loadLane(5*i+j, sram)
                for z in range(64):
                    A[i][j][z] = self.R[z]
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
        self.x = numpy.zeros(shape=(5,5), dtype=int)            #Contains indices of slices in the registers when a slice is loaded
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
        The (x,y) element of a slice can be accessed from a register as - R[self.x[x][y], where R[64] is a 64 bit array which refers to the 64 bit register 
        """
        if not pos%2:
            for i in range(5):
                for j in range(5):
                    if i==0 and j==0:
                        self.x[i][j] = 0
                    else:
                        if (5*i+j)%2:
                            self.x[i][j] = 2*(5*i+j)
                        else:
                            self.x[i][j] = 2*(5*i+j)-1
        else:
            for i in range(5):
                for j in range(5):
                    if i==0 and j==0:
                        self.x[i][j] = 1
                    else:
                        if (5*i+j)%2:
                            self.x[i][j] = 2*(5*i+j)+2
                        else:
                            self.x[i][j] = 2*(5*i+j)+1

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
                self.ParityReg[x] = self.ParityReg[x] ^ R[self.x[x][y]]

    def theta(self, R, nslice):
        """
        Slice wise Theta stage implementation
        """
        if (self.curslice != nslice):
            self.extractslice(nslice)
            self.curslice = nslice
        for x in range(5):
                self.tempParityReg[x] = self.tempParityReg[x]^(R[self.x[(x-2)%5][0]] ^ R[self.x[(x-2)%5][1]] ^ R[self.x[(x-2)%5][2]] ^ R[self.x[(x-2)%5][3]] ^ R[self.x[(x-2)%5][4]])
        for x in range(5):
            for y in range(5):
                R[self.x[(x-1)%5][y]] = self.tempParityReg[x] ^ R[self.x[(x-1)%5][y]]

    def pi(self, R, nslice):
        """
        Slice wise Pi stage implementation
        """
        if (self.curslice != nslice):
            self.extractslice(nslice)
            self.curslice = nslice
        for x in range(5):
            for y in range(5):
                self.temp[x][y] = R[self.x[(x+3*y)%5][x]]
        for x in range(5):
            for y in range(5):
                R[self.x[x][y]] = self.temp[x][y]

    def chi(self, R, nslice):
        """
        Slice wise Chi stage implementation
        """
        if (self.curslice != nslice):
            self.extractslice(nslice)
            self.curslice = nslice
        for x in range(5):
            for y in range(5):
                self.temp[x][y] = R[self.x[x][y]] ^ ((R[self.x[(x+1)%5][y]] ^ 1) & R[self.x[(x+2)%5][y]])
        for x in range(5):
            for y in range(5):
                R[self.x[x][y]] = self.temp[x][y]

    def iota(self, R, nslice, rnd):
        """
        Slice wise Iota stage implementation
        """
        if (self.curslice != nslice):
            self.extractslice(nslice)
            self.curslice = nslice
        R[self.x[0][0]] = R[self.x[0][0]] ^ int(self.RC[rnd][64-nslice-1])

class LaneProcessor:

    """
    Contains functions that simulate lane wise operations for the given datapath and constraints
    """

    def __init__(self):
        self.rotc = [1, 3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14,
		             27, 41, 56, 8, 25, 43, 62, 18, 39, 61, 20, 44 ]
                     #Keccak rotation offsets
        self.rhounit = numpy.zeros(shape=(4), dtype=int)

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

    def rho(self, R, lane, sram):
        """
        Applies Rho stage on a lane
        Lane(0,0) is omitted since it requires no rotation
        """
        if (lane > 0):
            offset = 8 + (math.ceil(lane/2.0)-1)*16            # Offset points to initial SRAM address
            rot1 = self.rotc[lane-1]        # Rotation constant
            rot1lowerbits = rot1%4                  # Extract lower 2 bits of rotation constant for first lane (fed to Barrel Shifter)
            rot1upperbits = int(rot1/4)             # Extract upper 4 bits of rotation constant for first lane (for register addressing)

            temp00 = numpy.zeros(shape=(4,), dtype=int)     # Temporary arrays for simulating Barrel Shifter (not required for hardware implementation)
            temp10 = numpy.zeros(shape=(4,), dtype=int)

            for r in range(16):                     # Iterate through all 16 register sections
            
                for i in range(4):                  # Read register section
                    temp00[i] = R[4*rot1upperbits+i]

                temp00 = self.shift_array_left(temp00, rot1lowerbits, 4)    # Shift left using Barrel Shifter

                self.rhounit = self.xor_arrays(temp00, [0])              # XOR shifted data in Rho Unit register

                if len(self.rhounit) != 4:
                    print("Rho Units corrupted during left shift")
                    sys.exit()

                for i in range(4):                  # Read next register section
                    temp10[i] = R[4*((rot1upperbits+1)%16)+i]

                temp10 = self.shift_array_right(temp10, 4-rot1lowerbits, 4) # Shift right using Barrel Shifter
                self.rhounit = self.xor_arrays(self.rhounit, temp10)  # XOR shifter data in Rho Unit register
                if len(self.rhounit) != 4:
                    print("Rho Units corrupted during right shift")
                    sys.exit()

                for i in range(4):                  # Interleave contents of Rho Unit registers and save to appropriate SRAM address
                    if lane%2:
                        sram[offset+r][2*i] = self.rhounit[i]
                    else:
                        sram[offset+r][2*i+1] = self.rhounit[i]

                rot1upperbits = (rot1upperbits+1)%16       # Increment register addresses

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
        R.loadSliceBlock(31, P.sram)
        S.storeParity(R.R, 63)
        for i in range(64):
            if (i%2 == 0):
                R.loadSliceBlock(int(i/2), P.sram)
            S.storeParity(R.R, i)
            S.theta(R.R, i)
            if (i%2 == 1):
                R.saveSliceBlock(int(i/2), P.sram)

    def fullrho(self, P, R, S, L):
        """
        Load lane pairs sequentially and apply Rho stage of entire state
        """
        for i in range(1, 25):
            R.loadLane(i, P.sram)
            L.rho(R.R, i, P.sram)

    def miniround(self, P, R, S, L, rnd):
        """
        Modified round
        Apply Pi, Chi and Iota stages on entire state
        """
        for i in range(64):
            if (i%2 == 0):
                R.loadSliceBlock(int(i/2), P.sram)
            S.pi(R.R, i)
            S.chi(R.R, i)
            S.iota(R.R, i, rnd)
            if (i%2 == 1):
                R.saveSliceBlock(int(i/2), P.sram)

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
        R = Register()
        S = SliceProcessor()
        L = LaneProcessor()

        self.readExternalRam(P.sram)

        #self.fullTheta(P, R, S, L)

        R.loadSliceBlock(31, P.sram)
        S.storeParity(R.R, 63)
        for i in range(64):
            if (i%2 == 0):
                R.loadSliceBlock(int(i/2), P.sram)
            S.storeParity(R.R, i)
            S.theta(R.R, i)
            if (i%2 == 1):
                R.saveSliceBlock(int(i/2), P.sram)

        for i in range(200):
            print("%d : "%i, end ='')
            for j in range(2):
                aggregate = 0
                for k in range(4):
                    aggregate += int((1<<(3-k))*P.sram[i][7-4*j-k])
                print("%X"%aggregate, end='')
            print('')

        # for i in range(63, -1, -1):
        #     print("%2d"%R.R[i], end='')
        # print('')

def main():

    sha = SHA3()
    #sha.test()
    sha.Keccak()

if __name__ == '__main__':
    main()