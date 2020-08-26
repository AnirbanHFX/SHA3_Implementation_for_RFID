library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity sha3 is port (
    clk : in std_logic;                                 -- Global clock
    sha3_datain : in std_logic_vector(7 downto 0);      -- Input to internal SRAM
    counter : in std_logic_vector(15 downto 0);         -- Global counter
    data_addr : in std_logic_vector(8 downto 0);        -- Address input to internal SRAM (Activates after end of conversion)
    sha3_dataout : out std_logic_vector(7 downto 0);    -- Output from internal SRAM
    EOC : out std_logic                                 -- Signal indicating end of SHA3 operations (safe to read from RAM)
);
end entity sha3;

architecture arch_sha3 of sha3 is

    component sram port (
        clk : in std_logic;                         -- RAM clock (data is latched if we = '1' and rising edge appears on clock)
        we : in std_logic;                          -- Write enable ('1' enables latching of data)
        addr: in std_logic_vector(8 downto 0);      -- Ram address (0-199 allowed)
        datain: in std_logic_vector(7 downto 0);    -- Input data
        dataout: out std_logic_vector(7 downto 0);  -- Output data
        cs : in std_logic                           -- Chip select logic (Chip enabled when cs = '1')
    );
    end component;

    component register64 port (
        clk: in std_logic;                          -- Register clock
        reset: in std_logic;                        -- Register reset logic
        d: in std_logic_vector(63 downto 0);        -- Register parallel input
        q: inout std_logic_vector(63 downto 0);     -- Register parallel output
        mode : in std_logic;                        -- Input mode select : '0' = serial in, '1' = parallel in
        slc : in std_logic;                         -- Select slice, for parallel input of a slice from Slice unit
        shift: in std_logic                         -- Shift amount logic : '0' = left shift 4 bits, '1' = left shift 2 bits
    );
    end component;

    component deinterleave port (
        wirein      : in std_logic_vector(7 downto 0);      -- Interleaved input
        wireout     : out std_logic_vector(3 downto 0);     -- Deinterleaved output to register
        leaved      : in std_logic;                         -- Logic '1' indicates input is interleaved and vice versa
        row         : in std_logic;                         -- Logic '1' indicates input is a row and '1' indicates input is a slice pair
        ctrl        : in std_logic_vector(1 downto 0)       -- Interleaver control logic
                                                            -- When selecting slice, ctrl == slice%4
                                                            -- When selecting row, ctrl%2 == row%2
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

    component laneproc port (
        bypass_lane : in std_logic;                     -- '1' when rho is bypassed and laneproc is used to write slices to RAM, '0' when computing rho
        clk : in std_logic;                             -- Clock input
        iclk : in std_logic;                            -- Inverted clock input
        cntr : in std_logic_vector(3 downto 0);         -- When computing rho : cntr addresses 16 register sections, when writing slices : cntr addresses 13 register sections
        lane : in std_logic_vector(4 downto 0);         -- Index identifying the lane loaded in the register
        reg : in std_logic_vector(63 downto 0);         -- Output of register
        ramaddr : out std_logic_vector(8 downto 0);     -- Returns sram address where rho unit contents need to be stored
        ramword : out std_logic_vector(7 downto 0);     -- Interleaver output - connected to input of RAM
        ramtrig : out std_logic;                        -- Write Enable logic of RAM
        ctrl : in std_logic_vector(1 downto 0);         -- Interleaver ctrl logic
        leaved : in std_logic                           -- Choose whether interleaver writes to leaved or non-interleaved word
    );
    end component;

    signal End_of_Conversion : std_logic;
    signal ci : integer;                                                -- Integral counter
    signal iclk : std_logic;

    -- sram signals --
    signal we : std_logic;                                              -- Write enable
    signal addr : std_logic_vector(8 downto 0);                         -- RAM address
    signal data, datain : std_logic_vector(7 downto 0);                 -- Ram input and output ports (initialized to content(0))
    signal ramclk : std_logic;                                          -- RAM clock
    signal chipselect : std_logic;                                      -- Chip select logic
    ------------------

    -- register signals --
    signal q : std_logic_vector(63 downto 0);                           -- Register output
    signal d : std_logic_vector(63 downto 0);                           -- Register input
    signal ctrl : std_logic_vector(1 downto 0);                         -- Select register slice (LSB), ctrl logic for interleaver and deinterleaver
    signal shift, mode : std_logic;                                     -- Shift : '1' - Shift 2 bits, '0' - Shift 4 bits; Mode : '1' - Parallel in, '0' - Serial in
    signal regclk : std_logic;                                          -- Register clock input
    signal regreset : std_logic;                                        -- Reset logic
    ----------------------

    -- slice mux/demux signals --
    signal regslc : std_logic;                                          -- Slice index modulo 2
    signal sliceout : std_logic_vector(24 downto 0);                    -- Output slice
    signal regslcin : std_logic_vector(49 downto 0);                    -- Input from registers
    -----------------------------

    -- Slice processor signals --
    signal inslice : std_logic_vector(24 downto 0);                     -- Input slice
    signal outslice : std_logic_vector(24 downto 0);                    -- Output slice
    signal slc : std_logic_vector(5 downto 0);                          -- Slice index (0-63)
    signal rnd : std_logic_vector(4 downto 0);                          -- Round index (0-23)
    signal parclk : std_logic;                                          -- Clock to parity register
    signal byp_ixp : std_logic;                                         -- Bypass logic for Iota, Chi, Pi
    signal byp_theta : std_logic;                                       -- Bypass logic for Theta
    -----------------------------

    -- Lane processor signals --
    signal byp_lane : std_logic;                                        -- Bypass logic
    signal rhoclk : std_logic;                                          -- Clock to rho registers
    signal irhoclk : std_logic;                                         -- Inverted clock to rho registers
    signal rhocntr : std_logic_vector(3 downto 0);                      -- Counter for addressing register sections (0-15)
    signal lane : std_logic_vector(4 downto 0);                         -- Lane index (1-24)
    signal ramaddress : std_logic_vector(8 downto 0);                   -- Ram address output (Lane processor computes address where a word must be saved after Rho operation)
    signal ramdata : std_logic_vector(7 downto 0);                      -- Word to be written to RAM
    signal divider : std_logic_vector(1 downto 0);                      -- Frequency divider (Counter is incremented after 3 clock cycles)
    signal ramtrigger : std_logic;                                      -- Trigger connected to write enable of RAM
    ----------------------------

    -- Deinterleaver output --
    signal deleave_d : std_logic_vector(3 downto 0);
    signal isleaved, isrow : std_logic;
    --------------------------

    signal iword, nword, sliceblock, laneid, offset : natural;        -- Variables used for various computations

    begin

        iclk <= not clk;
        irhoclk <= not rhoclk;
        chipselect <= '1';
        ci <= to_integer(unsigned(counter));

        EOC <= End_of_Conversion;                           -- Signal end of hash algorithm
        sha3_dataout <= data;                               -- Output RAM words

        ram : sram port map (ramclk, we, addr, datain, data, chipselect);
        r : register64 port map (regclk, regreset, d, q, mode, regslc, shift);
        dlv : deinterleave port map (wirein=>data, wireout=>deleave_d, leaved=>isleaved, row=>isrow, ctrl=>ctrl);

        slcmux : slicemux port map (q(49 downto 0), sliceout, regslc);
        slcdemux : slicedemux port map (outslice, regslcin, regslc);

        sproc : sliceproc port map (inslice, outslice, slc, rnd, parclk, byp_ixp, byp_theta);
        lproc : laneproc port map (byp_lane, rhoclk, irhoclk, rhocntr, lane, q, ramaddress, ramdata, ramtrigger, ctrl, isleaved);

        inslice <= sliceout;

        -- End of Conversion signal --
        EOCcontrol : process (clk) is
        begin
            if ci < 215 then
                End_of_Conversion <= '0';
            else
                End_of_Conversion <= '1';
            end if;
        end process EOCcontrol;

        -- SRAM Signals --
        SRAMcontrol : process (clk, iclk) is
        begin
            -- Initialize SRAM --
            if ci = 0 then
                addr <= (others => '0');
                ramclk <= clk;
                we <= '1';
                datain <= sha3_datain;
            elsif ci < 200 then
                ramclk <= clk;
                we <= '1';
                datain <= sha3_datain;
            -- Load Slice Block 31 --
            elsif ci = 200 then
                ramclk <= '0';
                we <= '0';
                datain <= (others => 'Z');
                addr <= std_logic_vector(to_unsigned(199-(15-31/2), addr'length));
            elsif ci >= 201 and ci < 213 then
                ramclk <= '0';
                we <= '0';
                datain <= (others => 'Z');
            elsif ci >= 213 and ci <= 214 then
                ramclk <= '0';
                we <= '0';
                datain <= (others => 'Z');
                addr <= std_logic_vector(to_unsigned(31/4, addr'length));
            -- End of operations --
            else
                ramclk <= '0';
                we <= '0';
                datain <= (others => 'Z');
                addr <= data_addr;
            end if;

            if rising_edge(iclk) then
                -- Initialize SRAM --
                if ci > 0 and ci < 200 then
                    addr <= addr + 1;
                end if;
            end if;

            if rising_edge(clk) then
                -- Load Slice Block 15 --
                if ci >= 201 and ci < 213 and to_integer(unsigned(addr)) - 16 >= 8 then
                    addr <= addr - 16;
                end if;
            end if;

        end process SRAMcontrol;

        -- De-interleaver Signals --
        DELEAVEcontrol : process (clk, iclk, counter) is
        begin
            -- Initialize SRAM --
            if ci < 200 then
                isleaved <= '0';
                isrow <= '0';
            elsif ci >= 200 and ci < 213 then
                isleaved <= '1';
                isrow <= '0';
            elsif ci >= 213 and ci <= 214 then
                isleaved <= '0';
                isrow <= '0';
            else
                isleaved <= '0';
                isrow <= '0';
            end if;
        end process DELEAVEcontrol;

        -- Register Signals --
        REGcontrol : process (clk, iclk) is
        begin
            -- Initialize SRAM --
            if ci = 0 then
                regreset <= '1';
                regclk <= '0';
                ctrl <= "00";
                mode <= '0';
                shift <= '0';
                d <= (others => '0');
            elsif ci < 200 then
                regreset <= '0';
                regclk <= '0';
                ctrl <= "00";
                mode <= '0';
                shift <= '0';
                d <= (others => '0');
            -- Load Slice Block 15 --
            elsif ci = 200 then
                regreset <= '0';
                regclk <= '0';
                ctrl <= "01";
                mode <= '0';
                shift <= '0';
                d(3 downto 0) <= deleave_d;
                d(63 downto 4) <= (others => '0');
            elsif ci >= 201 and ci < 213 then
                regreset <= '0';
                regclk <= clk;
                ctrl <= "01";
                mode <= '0';
                shift <= '0';
                d(3 downto 0) <= deleave_d;
                d(63 downto 4) <= (others => '0');
            elsif ci = 213 then
                regreset <= '0';
                regclk <= clk;
                ctrl <= "10";   -- Sliceblock = 31; (sliceblock rem 4)*2 = 4
                mode <= '0';
                shift <= '1';
                d(3 downto 0) <= deleave_d;
                d(63 downto 4) <= (others => '0');
            elsif ci = 214 then
                regreset <= '0';
                regclk <= '0';
                ctrl <= "10";
                mode <= '0';
                shift <= '1';
                d <= (others => '0');
            -- End of operations --
            else
                regreset <= '1';
                regclk <= '0';
                ctrl <= "00";
                mode <= '0';
                shift <= '0';
                d <= (others => '0');
            end if;
        end process REGcontrol;

        -- Multiplexer Signals --
        MUXcontrol : process (clk, iclk) is
        begin
            if ci < 200 then
                regslc <= '0';
            elsif ci >= 200 and ci <= 214 then
                regslc <= '1';
            else
                regslc <= '0';
            end if;
        end process MUXcontrol;

        -- Slice processor signals --
        SLICEcontrol : process (clk, iclk) is
        begin
            if ci <= 213 then
                slc <= (others => '0');
                rnd <= (others => '0');
                parclk <= '0';
                byp_ixp <= '1';
                byp_theta <= '1';
            -- Compute parity of slice 63 and store in reg --
            elsif ci = 214 then
                parclk <= clk;
            else 
                slc <= (others => '0');
                rnd <= (others => '0');
                parclk <= '0';
                byp_ixp <= '1';
                byp_theta <= '1';
            end if;

        end process SLICEcontrol;

        -- Lane processor signals --           
        LANEcontrol : process (clk, iclk) is
        begin
            if ci <= 214 then
                byp_lane <= '1';
                rhoclk <= '0';
                rhocntr <= (others => '0');
                lane <= (others => '0');
                divider <= (others => '0');
            else
                byp_lane <= '1';
                rhoclk <= '0';
                rhocntr <= (others => '0');
                lane <= (others => '0');
                divider <= (others => '0');
            end if;

        end process LANEcontrol;

    end architecture arch_sha3;