library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity sha3 is port (
    clk : in std_logic;                                 -- Global clock
    sha3_datain : in std_logic_vector(7 downto 0);      -- Input to internal SRAM
    counter : in std_logic_vector(31 downto 0);         -- Global counter
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
        dataout: out std_logic_vector(7 downto 0)   -- Output data
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

    signal End_of_Conversion : std_logic := '0';
    signal fasterclock : std_logic := '0';

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
    signal parclk : std_logic := '0';                                    -- Clock to parity register
    signal byp_ixp : std_logic := '1';                                  -- Bypass logic for Iota, Chi, Pi
    signal byp_theta : std_logic := '1';                                -- Bypass logic for Theta
    -----------------------------

    -- Lane processor signals --
    signal byp_lane : std_logic := '1';                                 -- Bypass logic
    signal rhoclk : std_logic := '0';                                   -- Clock to rho registers
    signal rhocntr : std_logic_vector(3 downto 0) := (others => '0');   -- Counter for addressing register sections (0-15)
    signal lane : std_logic_vector(4 downto 0) := (others => '0');      -- Lane index (1-24)
    signal ramaddress : std_logic_vector(8 downto 0);                   -- Ram address output (Lane processor computes address where a word must be saved after Rho operation)
    signal ramdata : std_logic_vector(7 downto 0);                      -- Word to be written to RAM
    signal divider : std_logic_vector(1 downto 0);                      -- Frequency divider (Counter is incremented after 3 clock cycles)
    signal ramtrigger : std_logic;                                      -- Trigger connected to write enable of RAM
    ----------------------------

    -- Deinterleaver output --
    signal deleave_d : std_logic_vector(3 downto 0);
    signal isleaved, isrow : std_logic := '0';
    --------------------------

    signal iword, nword, sliceblock, laneid, offset : natural;        -- Variables used for various computations

    begin

        fasterclock <= not fasterclock after 10 ns;

        EOC <= End_of_Conversion;                           -- Signal end of hash algorithm
        sha3_dataout <= data;                               -- Output RAM words

        ram : sram port map (ramclk, we, addr, datain, data);
        r : register64 port map (regclk, regreset, d, q, mode, regslc, shift);
        dlv : deinterleave port map (wirein=>data, wireout=>deleave_d, leaved=>isleaved, row=>isrow, ctrl=>ctrl);

        slcmux : slicemux port map (q(49 downto 0), sliceout, regslc);
        slcdemux : slicedemux port map (outslice, regslcin, regslc);

        sproc : sliceproc port map (inslice, outslice, slc, rnd, parclk, byp_ixp, byp_theta);
        lproc : laneproc port map (byp_lane, rhoclk, rhocntr, lane, q, ramaddress, ramdata, ramtrigger, ctrl, isleaved);

        inslice <= sliceout;

        SHA3 : process (clk, fasterclock, divider, ramtrigger) is
            variable k : natural;
            variable loopsize : natural;
            variable innerloop : natural;
            variable modifiedrnd : natural;
        begin
            --- Initialize SRAM ---
            if to_integer(unsigned(counter)) = 0 then
                ramclk <= clk;
                regreset <= '1';
                addr <= (others => '0');
                datain <= sha3_datain;
            elsif to_integer(unsigned(counter)) < 200 then
                ramclk <= clk;
                regreset <= '0';
                we <= '1';
                datain <= sha3_datain;
                if falling_edge(clk) then
                    addr <= addr + 1;
                end if;
            --- Load Slice Block 15 ---
            elsif to_integer(unsigned(counter)) = 200 then 
                datain <= (others => 'Z');
                isleaved <= '1';
                d(3 downto 0) <= deleave_d;
                byp_lane <= '1';
                byp_theta <= '1';
                byp_ixp <= '1';
                mode <= '0';
                we <= '0';
                shift <= '0';
                ctrl <= "01";
                sliceblock <= 31;
                iword <= 199-(15-sliceblock/2);
                addr <= std_logic_vector(to_unsigned(iword, addr'length));
                regslc <= '1';
            elsif to_integer(unsigned(counter)) >= 201 and to_integer(unsigned(counter)) < 213 then
                d(3 downto 0) <= deleave_d;   
                if clk'event then
                    regclk <= clk;
                end if;
                addr <= std_logic_vector(to_unsigned(iword, addr'length));
                if rising_edge(clk) then
                    if iword - 16 >= 8 then
                        iword <= iword - 16;
                    end if;
                end if;
            elsif to_integer(unsigned(counter)) = 213 then
                d(3 downto 0) <= deleave_d;
                nword <= (sliceblock rem 4)*2;
                isleaved <= '0';
                if nword = 0 then
                    ctrl <= "00";
                elsif nword = 2 then
                    ctrl <= "01";
                elsif nword = 4 then
                    ctrl <= "10";
                else
                    ctrl <= "11";
                end if;
                shift <= '1';
                addr <= std_logic_vector(to_unsigned(sliceblock/4, addr'length));
                if clk'event then
                    regclk <= clk;
                end if;
            --- Calculate Parity and store for Slice 63 ---
            elsif to_integer(unsigned(counter)) = 214 then
                if falling_edge(clk) then
                    regclk <= '0';
                end if;
                if clk'event then
                    parclk <= clk;
                end if;
            
            --- PERFORM THETA ON ENTIRE STATE ---
            elsif to_integer(unsigned(counter)) >= 215 and to_integer(unsigned(counter)) <= 246+32*31 then
                k := 0;
                loopsize := 32;
                ramclk <= clk;
                while(k <= 31) loop
                    if to_integer(unsigned(counter)) = 215+loopsize*k then
                        datain <= (others => 'Z');
                        we <= '0';
                        parclk <= '0';
                        regclk <= '0';
                        if not rising_edge(clk) then
                            regreset <= clk;
                        end if;
                    elsif to_integer(unsigned(counter)) = 216+loopsize*k then 
                        d(3 downto 0) <= deleave_d;
                        isleaved <= '1';
                        we <= '0';
                        mode <= '0';
                        regreset <= '0';
                        shift <= '0';
                        ctrl <= std_logic_vector(to_unsigned(k rem 4, ctrl'length));
                        sliceblock <= k;
                        regclk <= '0';
                        parclk <= '0';
                        iword <= 199-(15-sliceblock/2);
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                    elsif to_integer(unsigned(counter)) >= 215+2+loopsize*k and to_integer(unsigned(counter)) < 215+14+loopsize*k then     -- LOAD SLICE BLOCK
                        d(3 downto 0) <= deleave_d;
                        if clk'event then
                            regclk <= clk;
                        end if;
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        if rising_edge(clk) then
                            if iword - 16 >= 8 then
                                iword <= iword - 16;
                            end if;
                        end if;
                    elsif to_integer(unsigned(counter)) = 215+14+loopsize*k then
                        d(3 downto 0) <= deleave_d;
                        nword <= (sliceblock rem 4)*2;
                        isleaved <= '0';
                        byp_theta <= '0';
                        if nword = 0 then
                            ctrl <= "00";
                        elsif nword = 2 then
                            ctrl <= "01";
                        elsif nword = 4 then
                            ctrl <= "10";
                        else
                            ctrl <= "11";
                        end if;
                        shift <= '1';
                        addr <= std_logic_vector(to_unsigned(sliceblock/4, addr'length));
                        if clk'event then
                            regclk <= clk;
                        end if;
                    -- Apply Theta on Block k --
                    elsif to_integer(unsigned(counter)) = 230+loopsize*k then
                        if falling_edge(clk) then
                            regclk <= '0';
                        end if;
                        regslc <= '0';
                        d(49 downto 0) <= regslcin(49 downto 0);
                        mode <= '1';
                        shift <= '0';
                    elsif to_integer(unsigned(counter)) <= 232+loopsize*k and to_integer(unsigned(counter)) > 230+loopsize*k then
                        if not rising_edge(clk) then
                            regclk <= clk;      -- Theta current slice and store in register
                            parclk <= clk;
                        end if;
                        if falling_edge(clk) and regslc = '0' then
                            regslc <= '1';
                        end if;
                        d(49 downto 0) <= regslcin(49 downto 0);

                    -- SAVE REGISTER CONTENTS TO SRAM
                    elsif to_integer(unsigned(counter)) = 233+loopsize*k then 
                        ctrl <= std_logic_vector(to_unsigned(k rem 4, ctrl'length));
                        sliceblock <= k;
                        datain <= ramdata;
                        iword <= 199-(15-sliceblock/2);
                        isleaved <= '1';
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        rhocntr <= "1100";
                    elsif to_integer(unsigned(counter)) >= 234+loopsize*k and to_integer(unsigned(counter)) < 246+loopsize*k then
                        we <= '1';
                        datain <= ramdata;
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        if rising_edge(clk) then
                            if to_integer(unsigned(rhocntr)) > 0 then
                                rhocntr <= rhocntr - 1;
                            end if;
                            if iword - 16 >= 8 then
                                iword <= iword - 16;
                            end if;
                        end if;
                        -- if to_integer(unsigned(counter)) = 245+loopsize*k then
                        --     if falling_edge(clk) then
                        --         isleaved <= '0';
                        --     end if;
                        -- end if ;
                    elsif to_integer(unsigned(counter)) = 246+loopsize*k then
                        rhocntr <= (others => '0');
                        we <= '1';
                        nword <= (sliceblock rem 4)*2;
                        isleaved <= '0';
                        datain <= ramdata;
                        if nword = 0 then
                            ctrl <= "00";
                        elsif nword = 2 then
                            ctrl <= "01";
                        elsif nword = 4 then
                            ctrl <= "10";
                        else
                            ctrl <= "11";
                        end if;
                        shift <= '1';
                        addr <= std_logic_vector(to_unsigned(sliceblock/4, addr'length));
                    end if;
                    k := k+1;
                end loop;
            -- PERFORM RHO ON ENTIRE STATE --
            -- 759 -> 1239 (+480)
            elsif to_integer(unsigned(counter)) >= 1239 and to_integer(unsigned(counter)) <= 1238+51*24 then
                k := 1;
                loopsize := 51;
                while (k <= 24) loop
                    if to_integer(unsigned(counter)) = 1239+loopsize*(k-1) then     -- LOAD LANE k
                        divider <= (others => '0');
                        rhocntr <= (others => '0');
                        ramclk <= '0';
                        rhoclk <= '0';
                        byp_lane <= '1';
                        isrow <= '1';
                        isleaved <= '1';
                        mode <= '0';
                        shift <= '0';
                        d(3 downto 0) <= deleave_d;
                        byp_theta <= '1';
                        regreset <= '1';
                        we <= '0';
                        if (k rem 2) = 0 then
                            ctrl <= "00";
                        else
                            ctrl <= "01";
                        end if;
                        offset <= 8+((k+1)/2 - 1)*16 + 15; -- 8 + (lanepair - 1)*16 + 15;
                        addr <= std_logic_vector(to_unsigned(offset, addr'length));
                    elsif to_integer(unsigned(counter)) >= 1239+1+loopsize*(k-1) and to_integer(unsigned(counter)) < 1239+17+loopsize*(k-1) then
                        regreset <= '0';
                        d(3 downto 0) <= deleave_d;
                        if not rising_edge(clk) then
                            regclk <= clk;
                        end if;
                        if rising_edge(clk) and to_integer(unsigned(addr)) > 8+((k+1)/2 - 1)*16 then
                            addr <= addr - 1;
                        end if;
                    elsif to_integer(unsigned(counter)) >= 1239+17+loopsize*(k-1) and to_integer(unsigned(counter)) <= 1289+loopsize*(k-1) then
                        rhoclk <= clk;
                        byp_lane <= '0';
                        we <= '1';
                        datain <= ramdata;
                        ramclk <= ramtrigger;
                        addr <= ramaddress;
                        lane <= std_logic_vector(to_unsigned(k-1, lane'length));
                        if rising_edge(clk) then
                            divider <= std_logic_vector(to_unsigned((to_integer(unsigned(divider)) + 1) rem 2, divider'length));
                        end if;
                        if falling_edge(divider(0)) then
                            rhocntr <= std_logic_vector(to_unsigned((to_integer(unsigned(rhocntr)) + 1) rem 16, rhocntr'length));
                        end if;
                    end if;
                    k := k+1;
                end loop;
            --- END OF OPERATIONS ---
            -- PERFORM 23 CONSECUTIVE MODIFIED ROUNDS OF SHA3 --
                -- * Pi, Chi, Iota, Theta operations on entire state
                -- * Rho on entire state
                -- 1371 -> 2463 (+1092)
            elsif to_integer(unsigned(counter)) >= 2463 and to_integer(unsigned(counter)) <= 4725+2263*22 then

                loopsize := 2263;
                modifiedrnd := 0;
                
                -- OUTER LOOP FOR REPEATING ROUNDS --
                while (modifiedrnd <= 22) loop

                    --- Load Slice Block 15 ---
                    -- 200 -> 2463 (+2263)
                    if to_integer(unsigned(counter)) = 2463 + loopsize*modifiedrnd then 
                        if rising_edge(clk) and to_integer(unsigned(counter)) /= 2463 then
                            rnd <= rnd + 1;
                        end if;
                        datain <= (others => 'Z');
                        isleaved <= '1';
                        d(3 downto 0) <= deleave_d;
                        byp_lane <= '1';
                        byp_theta <= '1';
                        byp_ixp <= '1';
                        mode <= '0';
                        we <= '0';
                        shift <= '0';
                        ctrl <= "01";
                        sliceblock <= 31;
                        iword <= 199-(15-sliceblock/2);
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        regslc <= '1';
                        slc <= std_logic_vector(to_unsigned(63, slc'length));
                    elsif to_integer(unsigned(counter)) >= 2464+loopsize*modifiedrnd and to_integer(unsigned(counter)) < 2476+loopsize*modifiedrnd then
                        d(3 downto 0) <= deleave_d;   
                        if clk'event then
                            regclk <= clk;
                        end if;
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        if rising_edge(clk) then
                            if iword - 16 >= 8 then
                                iword <= iword - 16;
                            end if;
                        end if;
                    elsif to_integer(unsigned(counter)) = 2476+loopsize*modifiedrnd then
                        d(3 downto 0) <= deleave_d;
                        nword <= (sliceblock rem 4)*2;
                        isleaved <= '0';
                        if nword = 0 then
                            ctrl <= "00";
                        elsif nword = 2 then
                            ctrl <= "01";
                        elsif nword = 4 then
                            ctrl <= "10";
                        else
                            ctrl <= "11";
                        end if;
                        shift <= '1';
                        addr <= std_logic_vector(to_unsigned(sliceblock/4, addr'length));
                        if clk'event then
                            regclk <= clk;
                        end if;
                    --- Calculate Parity and store for Slice 63 ---
                    elsif to_integer(unsigned(counter)) = 2477+loopsize*modifiedrnd then
                        if falling_edge(clk) then
                            regclk <= '0';
                        end if;
                        if clk'event then
                            parclk <= clk;
                        end if;
                    
                    --- PERFORM IOTA, CHI, PI, THETA ON ENTIRE STATE ---
                    elsif to_integer(unsigned(counter)) >= 2478+loopsize*modifiedrnd and to_integer(unsigned(counter)) <= 2509+32*31+loopsize*modifiedrnd then
                        k := 0;
                        innerloop := 32;
                        ramclk <= clk;
                        while(k <= 31) loop
                            if to_integer(unsigned(counter)) = 2478+innerloop*k+loopsize*modifiedrnd then
                                datain <= (others => 'Z');
                                we <= '0';
                                parclk <= '0';
                                regclk <= '0';
                                if not rising_edge(clk) then
                                    regreset <= clk;
                                end if;
                            elsif to_integer(unsigned(counter)) = 2479+innerloop*k+loopsize*modifiedrnd then 
                                d(3 downto 0) <= deleave_d;
                                isleaved <= '1';
                                we <= '0';
                                mode <= '0';
                                regreset <= '0';
                                shift <= '0';
                                ctrl <= std_logic_vector(to_unsigned(k rem 4, ctrl'length));
                                sliceblock <= k;
                                regclk <= '0';
                                parclk <= '0';
                                iword <= 199-(15-sliceblock/2);
                                addr <= std_logic_vector(to_unsigned(iword, addr'length));
                            elsif to_integer(unsigned(counter)) >= 2478+2+innerloop*k+loopsize*modifiedrnd and to_integer(unsigned(counter)) < 2478+14+innerloop*k+loopsize*modifiedrnd then     -- LOAD SLICE BLOCK
                                d(3 downto 0) <= deleave_d;
                                if clk'event then
                                    regclk <= clk;
                                end if;
                                addr <= std_logic_vector(to_unsigned(iword, addr'length));
                                if rising_edge(clk) then
                                    if iword - 16 >= 8 then
                                        iword <= iword - 16;
                                    end if;
                                end if;
                            elsif to_integer(unsigned(counter)) = 2478+14+innerloop*k+loopsize*modifiedrnd then
                                d(3 downto 0) <= deleave_d;
                                nword <= (sliceblock rem 4)*2;
                                isleaved <= '0';
                                if nword = 0 then
                                    ctrl <= "00";
                                elsif nword = 2 then
                                    ctrl <= "01";
                                elsif nword = 4 then
                                    ctrl <= "10";
                                else
                                    ctrl <= "11";
                                end if;
                                shift <= '1';
                                addr <= std_logic_vector(to_unsigned(sliceblock/4, addr'length));
                                if clk'event then
                                    regclk <= clk;
                                end if;
                            -- Apply Theta on Block k --
                            elsif to_integer(unsigned(counter)) = 2493+innerloop*k+loopsize*modifiedrnd then
                                if falling_edge(clk) then
                                    regclk <= '0';
                                end if;
                                byp_theta <= '0';
                                byp_ixp <= '0';
                                slc <= std_logic_vector(to_unsigned(sliceblock*2, slc'length));
                                regslc <= '0';
                                d(49 downto 0) <= regslcin(49 downto 0);
                                mode <= '1';
                                shift <= '0';
                            elsif to_integer(unsigned(counter)) <= 2495+innerloop*k+loopsize*modifiedrnd and to_integer(unsigned(counter)) > 2493+innerloop*k+modifiedrnd*loopsize then
                                if not rising_edge(clk) then
                                    regclk <= clk;      -- Theta current slice and store in register
                                    parclk <= clk;
                                end if;
                                if falling_edge(clk) and regslc = '0' then
                                    regslc <= '1';
                                    slc <= slc + 1;
                                end if;
                                d(49 downto 0) <= regslcin(49 downto 0);

                            -- SAVE REGISTER CONTENTS TO SRAM
                            elsif to_integer(unsigned(counter)) = 2496+innerloop*k+loopsize*modifiedrnd then 
                                ctrl <= std_logic_vector(to_unsigned(k rem 4, ctrl'length));
                                sliceblock <= k;
                                datain <= ramdata;
                                iword <= 199-(15-sliceblock/2);
                                isleaved <= '1';
                                addr <= std_logic_vector(to_unsigned(iword, addr'length));
                                rhocntr <= "1100";
                            elsif to_integer(unsigned(counter)) >= 2497+innerloop*k+loopsize*modifiedrnd and to_integer(unsigned(counter)) < 2509+innerloop*k+loopsize*modifiedrnd then
                                we <= '1';
                                datain <= ramdata;
                                addr <= std_logic_vector(to_unsigned(iword, addr'length));
                                if rising_edge(clk) then
                                    if to_integer(unsigned(rhocntr)) > 0 then
                                        rhocntr <= rhocntr - 1;
                                    end if;
                                    if iword - 16 >= 8 then
                                        iword <= iword - 16;
                                    end if;
                                end if;
                            elsif to_integer(unsigned(counter)) = 2509+innerloop*k+loopsize*modifiedrnd then
                                rhocntr <= (others => '0');
                                we <= '1';
                                nword <= (sliceblock rem 4)*2;
                                isleaved <= '0';
                                datain <= ramdata;
                                if nword = 0 then
                                    ctrl <= "00";
                                elsif nword = 2 then
                                    ctrl <= "01";
                                elsif nword = 4 then
                                    ctrl <= "10";
                                else
                                    ctrl <= "11";
                                end if;
                                shift <= '1';
                                addr <= std_logic_vector(to_unsigned(sliceblock/4, addr'length));
                            end if;
                            k := k+1;
                        end loop;
                    -- PERFORM RHO ON ENTIRE STATE --
                    -- 759 -> 1239 (+480)
                    -- 1239 -> 3502 (+2263)
                    elsif to_integer(unsigned(counter)) >= 3502+loopsize*modifiedrnd and to_integer(unsigned(counter)) <= 3501+51*24+loopsize*modifiedrnd then
                        k := 1;
                        innerloop := 51;
                        while (k <= 24) loop
                            if to_integer(unsigned(counter)) = 3502+innerloop*(k-1)+modifiedrnd*loopsize then     -- LOAD LANE k
                                divider <= (others => '0');
                                rhocntr <= (others => '0');
                                ramclk <= '0';
                                rhoclk <= '0';
                                byp_lane <= '1';
                                byp_theta <= '1';
                                byp_ixp <= '1';
                                isrow <= '1';
                                isleaved <= '1';
                                mode <= '0';
                                shift <= '0';
                                d(3 downto 0) <= deleave_d;
                                byp_theta <= '1';
                                regreset <= '1';
                                we <= '0';
                                if (k rem 2) = 0 then
                                    ctrl <= "00";
                                else
                                    ctrl <= "01";
                                end if;
                                offset <= 8+((k+1)/2 - 1)*16 + 15; -- 8 + (lanepair - 1)*16 + 15;
                                addr <= std_logic_vector(to_unsigned(offset, addr'length));
                            elsif to_integer(unsigned(counter)) >= 3502+1+innerloop*(k-1)+loopsize*modifiedrnd and to_integer(unsigned(counter)) < 3502+17+innerloop*(k-1)+modifiedrnd*loopsize then
                                regreset <= '0';
                                d(3 downto 0) <= deleave_d;
                                if not rising_edge(clk) then
                                    regclk <= clk;
                                end if;
                                if rising_edge(clk) and to_integer(unsigned(addr)) > 8+((k+1)/2 - 1)*16 then
                                    addr <= addr - 1;
                                end if;
                            elsif to_integer(unsigned(counter)) >= 3502+17+innerloop*(k-1)+modifiedrnd*loopsize and to_integer(unsigned(counter)) <= 3552+innerloop*(k-1)+modifiedrnd*loopsize then
                                rhoclk <= clk;
                                byp_lane <= '0';
                                we <= '1';
                                datain <= ramdata;
                                ramclk <= ramtrigger;
                                addr <= ramaddress;
                                lane <= std_logic_vector(to_unsigned(k-1, lane'length));
                                if rising_edge(clk) then
                                    divider <= std_logic_vector(to_unsigned((to_integer(unsigned(divider)) + 1) rem 2, divider'length));
                                end if;
                                if falling_edge(divider(0)) then
                                    rhocntr <= std_logic_vector(to_unsigned((to_integer(unsigned(rhocntr)) + 1) rem 16, rhocntr'length));
                                end if;
                            end if;
                            k := k+1;
                        end loop;
                    end if;

                    modifiedrnd := modifiedrnd + 1;
                end loop;

            else
                we <= '0';
                rhoclk <= '0';
                byp_ixp <= '1';
                byp_theta <= '1';
                isleaved <= '0';
                isrow <= '0';
                regclk <= '0';
                parclk <= '0';
                datain <= (others => 'Z');
                byp_lane <= '1';
                regreset <= '1';
                addr <= data_addr;
                End_of_Conversion <= '1';
            end if;
        end process SHA3;

    end architecture arch_sha3;