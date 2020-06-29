library ieee;
use ieee.std_logic_1164.all;

entity sha3 is port (
    clk : in std_logic;                                 -- Global clock
    sha3_datain : in std_logic_vector(7 downto 0);      -- Input to internal SRAM
    counter : in std_logic_vector(31 downto 0);         -- Global counter
    data_addr : in std_logic_vector(8 downto 0);        -- Address input to internal SRAM (Activates after end of conversion)
    sha3_dataout : out std_logic_vector(7 downto 0);    -- Output from internal SRAM
    EOC : out std_logic                                 -- Signal indicating end of SHA3 operations (safe to read from RAM)
);
end entity sha3;

architecture arch_sha3_tb of sha3_tb is

    component sram port (
        clk : in std_logic;                         -- RAM clock (data is latched if we = '1' and rising edge appears on clock)
        we : in std_logic;                          -- Write enable ('1' enables latching of data)
        addr: in std_logic_vector(8 downto 0);      -- Ram address (0-199 allowed)
        datain: in std_logic_vector(7 downto 0);    -- Input data
        dataout: out std_logic_vector(7 downto 0)   -- Output data
    );
    end component;

    component register port (
        clk: in std_logic;                          -- Register clock
        reset: in std_logic;                        -- Register reset logic
        d: in std_logic_vector(63 downto 0);        -- Register parallel input
        q: inout std_logic_vector(63 downto 0);     -- Register parallel output
        mode : in std_logic;                        -- Input mode select : '0' = serial in, '1' = parallel in
        slc : in std_logic;                         -- Select slice, for parallel input of a slice from Slice unit
        shift: in std_logic                         -- Shift amount logic : '0' = left shift 4 bits, '1' = left shift 2 bits
    );
    end component;

    component slicemux port (
        datain : in std_logic_vector(49 downto 0);      -- Input from register outputs
        dataout : out std_logic_vector(24 downto 0);    -- Slice output
        sel : in std_logic                              -- Slice index modulo 2
    );
    end component;

    component slicedemux port (
        datain : in std_logic_vector(24 downto 0);      -- Slice output from sliceprocessor unit
        dataout : out std_logic_vector(49 downto 0);    -- Output connected to parallel inputs of 64 bit registers
        sel : in std_logic                              -- Logic for selecting slice (modulo 2)
    );
    end component;

    component sliceproc port (
        slicein : in std_logic_vector(24 downto 0);         -- Input slice from slice-mux
        sliceout : out std_logic_vector(24 downto 0);       -- Output slice to slice-demux
        slice : in std_logic_vector(5 downto 0);            -- Round index for Iota stage
        roundn : in std_logic_vector(4 downto 0);           -- For iota
        storeparity : in std_logic;                         -- Rising edge causes parity of current slice to be stored in parity register
        bypass_ixp : in std_logic;                          -- Logic 1 bypasses pi, chi, iota
        bypass_theta : in std_logic                         -- Logic 1 bypasses theta
    );
    end component;

    -- sram signals --
    signal we : std_logic := '1';                                       -- Write enable
    signal addr : std_logic_vector(8 downto 0) := (others => '0');      -- RAM address
    signal data, datain : std_logic_vector(7 downto 0);                 -- Ram input and output ports (initialized to content(0))
    signal ramclk : std_logic := '0';                                   -- RAM clock
    ------------------

    -- register signals --
    signal q : std_logic_vector(63 downto 0);                           -- Register output
    signal d : std_logic_vector(63 downto 0) := (others => '0');        -- Register input
    signal ctrl : std_logic_vector(1 downto 0) := "00";                 -- Select register slice (LSB), ctrl logic for interleaver and deinterleaver
    signal shift, mode : std_logic := '0';                              -- Shift : '1' - Shift 2 bits, '0' - Shift 4 bits; Mode : '1' - Parallel in, '0' - Serial in
    signal regclk : std_logic := '0';                                   -- Register clock input
    signal regreset : std_logic := '0';                                 -- Reset logic
    ----------------------

    -- slice mux/demux signals --
    signal regslc : std_logic := '0';                                   -- Slice index modulo 2
    signal sliceout : std_logic_vector(24 downto 0);                    -- Output slice
    signal regslcin : std_logic_vector(49 downto 0);                    -- Input from registers
    -----------------------------

    -- Slice processor signals --
    signal inslice : std_logic_vector(24 downto 0);                     -- Input slice
    signal outslice : std_logic_vector(24 downto 0);                    -- Output slice
    signal slc : std_logic_vector(5 downto 0) := (others => '0');       -- Slice index (0-63)
    signal rnd : std_logic_vector(4 downto 0) := (others => '0');       -- Round index (0-23)
    signal parclk : std_logic := '0'                                    -- Clock to parity register
    signal byp_ixp : std_logic := '1';                                  -- Bypass logic for Iota, Chi, Pi
    signal byp_theta : std_logic := '1';                                -- Bypass logic for Theta
    -----------------------------

    -- Lane processor signals --
    signal byp_lane : std_logic := '1';                                 -- Bypass logic
    signal rhoclk : std_logic := '0';                                   -- Clock to rho registers
    signal rhocntr : std_logic_vector(3 downto 0) := (others => '0');   -- Counter for addressing register sections (0-15)
    signal lanepr : std_logic_vector(4 downto 0) := (others => '0');    -- Lanepair index (1-12)
    signal ramaddress : std_logic_vector(8 downto 0);                   -- Ram address output (Lane processor computes address where a word must be saved after Rho operation)
    signal ramdata : std_logic_vector(7 downto 0);                      -- Word to be written to RAM
    signal divider : std_logic_vector(1 downto 0);                      -- Frequency divider (Counter is incremented after 3 clock cycles)
    signal ramtrigger : std_logic;                                      -- Trigger connected to write enable of RAM
    ----------------------------

    -- Deinterleaver output --
    signal deleave_d : std_logic_vector(3 downto 0);
    --------------------------

    begin

        

    end architecture arch_sha3_tb;