-- SHA3 control block

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity sha3_trial is port(
    clk : in std_logic;                                 -- Global clock
    sha3_datain : in std_logic_vector(7 downto 0);      -- Input to internal SRAM
    counter : in std_logic_vector(31 downto 0);         -- Global counter
    data_addr : in std_logic_vector(8 downto 0);        -- Address input to internal SRAM (Activates after end of conversion)
    sha3_dataout : out std_logic_vector(7 downto 0);    -- Output from internal SRAM
    EOC : out std_logic                                 -- Signal indicating end of SHA3 operations (safe to read from RAM)
);
end entity sha3_trial;

architecture arch_sha3_trial of sha3_trial is

    component sram port (
        clk : in std_logic;                         -- RAM clock (data is latched if we = '1' and rising edge appears on clock)
        we : in std_logic;                          -- Write enable ('1' enables latching of data)
        addr: in std_logic_vector(8 downto 0);      -- Ram address (0-199 allowed)
        datain: in std_logic_vector(7 downto 0);    -- Input data
        dataout: out std_logic_vector(7 downto 0)   -- Output data
    );
    end component;

    component register0 port(
        clk: in std_logic;                          -- Register clock
        reset: in std_logic;                        -- Register reset logic
        d: in std_logic_vector(63 downto 0);        -- Register parallel input
        q: inout std_logic_vector(63 downto 0);     -- Register parallel output
        mode : in std_logic;                        -- Input mode select : '0' = serial in, '1' = parallel in
        slc : in std_logic_vector(1 downto 0);      -- Select slice, for parallel input of a slice from Slice unit
        shift: in std_logic                         -- Shift amount logic : '0' = left shift 4 bits, '1' = left shift 2 bits
    );
    end component;

    component register1 port(
        clk: in std_logic;                          -- Register clock
        reset: in std_logic;                        -- Register reset logic
        d: in std_logic_vector(63 downto 0);        -- Register parallel input
        q: inout std_logic_vector(63 downto 0);     -- Register parallel output
        mode : in std_logic;                        -- Input mode select : '0' = serial in, '1' = parallel in
        slc : in std_logic_vector(1 downto 0);      -- Select slice, for parallel input of a slice from Slice unit
        shift: in std_logic                         -- Shift amount logic : '0' = left shift 4 bits, '1' = left shift 2 bits
    );
    end component;

    component deinterleave port(
        wirein      : in std_logic_vector(7 downto 0);      -- Interleaved input
        wireup      : out std_logic_vector(3 downto 0);     -- Deinterleaved output to upper register
        wiredown    : out std_logic_vector(3 downto 0);     -- Deinterleaved output to lower register
        ctrl        : in std_logic_vector(1 downto 0)       -- Interleaver control logic
    );
    end component;

    component slicemux port (
        datain : in std_logic_vector(99 downto 0);      -- Input from register outputs
        dataout : out std_logic_vector(24 downto 0);    -- Slice output
        sel : in std_logic_vector(1 downto 0)           -- Slice index modulo 4
    );
    end component;

    component slicedemux is port (
        datain : in std_logic_vector(24 downto 0);         -- Slice output from sliceprocessor unit
        dataout : out std_logic_vector(99 downto 0);       -- Output connected to parallel inputs of 64 bit registers
        sel : in std_logic_vector(1 downto 0)              -- Logic for selecting slice (modulo 4)
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
        lanepair : in std_logic_vector(4 downto 0);     -- Index identifying the pair of lanes loaded to registers
        regup : in std_logic_vector(63 downto 0);       -- Output of upper register
        regdwn : in std_logic_vector(63 downto 0);      -- Output of lower register
        ramaddr : out std_logic_vector(8 downto 0);     -- Returns sram address where rho unit contents need to be stored
        ramword : out std_logic_vector(7 downto 0);     -- Interleaver output - connected to input of RAM
        ramtrig : out std_logic;                        -- Write Enable logic of RAM
        ctrl : in std_logic_vector                      -- Interleaver ctrl logic
    );
    end component;

    signal End_of_Conversion : std_logic := '0';

    signal fasterclock : std_logic := '0';                              -- Fast clock used for performing asynchronous calculations by the simulator, not required for synthesis
    
    -- sram signals --
    signal we : std_logic := '1';                                       -- Write enable
    signal addr : std_logic_vector(8 downto 0) := (others => '0');      -- RAM address
    signal data, datain : std_logic_vector(7 downto 0);                 -- Ram input and output ports (initialized to content(0))
    ------------------

    -- register signals --
    signal q1, q2 : std_logic_vector(63 downto 0);                      -- Register outputs
    signal d1, d2 : std_logic_vector(63 downto 0) := (others => '0');   -- Register inputs 
    signal ctrl : std_logic_vector(1 downto 0) := "00";                 -- Control logic for selecting register slice, also used for interleaver and deinterleaver
    signal shift, mode : std_logic := '0';                              -- Shift : '1' - Shift 2 bits, '0' - Shift 4 bits; Mode : '1' - Parallel in, '0' - Serial in
    signal regclk : std_logic := '0';                                   -- Register clock input
    signal regreset: std_logic := '0';                                  -- Reset logic
    ----------------------

    -- slice mux/demux signals --
    signal regslc : std_logic_vector(1 downto 0) := "00";               -- Slice index modulo 4
    signal sliceout : std_logic_vector(24 downto  0);                   -- Output slice
    signal regslcin : std_logic_vector(99 downto 0);                    -- Input from registers
    -----------------------------

    -- slice processor signals --
    signal inslice : std_logic_vector(24 downto 0);                     -- Input slice
    signal outslice : std_logic_vector(24 downto 0);                    -- Output slice
    signal slc : std_logic_vector(5 downto 0) := (others => '0');       -- Slice index (0-63)
    signal rnd : std_logic_vector(4 downto 0) := (others => '0');       -- Round index (0-23)
    signal parclk : std_logic := '0';                                   -- Clock to parity register
    signal byp_ixp : std_logic := '1';                                  -- Bypass logic for Iota, Chi, Pi
    signal byp_theta : std_logic := '1';                                -- Bypass logic for Theta
    -----------------------------

    -- lane processor signals --
    signal byp_lane : std_logic := '1';                                 -- Bypass logic
    signal rhoclk : std_logic := '0';                                   -- Clock to rho registers
    signal rhocntr : std_logic_vector(3 downto 0) := (others => '0');   -- Counter for addressing register sections (0-15)
    signal lanepr : std_logic_vector(4 downto 0) := (others => '0');    -- Lanepair index (1-12)
    signal ramaddress : std_logic_vector(8 downto 0);                   -- Ram address output (Lane processor computes address where a word must be saved after Rho operation)
    signal ramdata : std_logic_vector(7 downto 0);                      -- Word to be written to RAM
    signal divider : std_logic_vector(1 downto 0);                      -- Frequency divider (Counter is incremented after 3 clock cycles)
    signal ramtrigger : std_logic;                                      -- Trigger connected to write enable of RAM
    ----------------------------

    -- Deinterleaver Outputs --
    signal deleave_d1, deleave_d2 : std_logic_vector(3 downto 0); 
    ---------------------------

    constant Period : time := 100 ns;                                   -- Period of internal clock
    constant fastPeriod : time := 20 ns;                                -- Period of fast clock used for asynchronous computation by simulator

    signal iword, nword, sliceblock, lanepair, offset : natural;        -- Variables used for various computations

    begin

        EOC <= End_of_Conversion;                                       -- Signal when SHA3 algorithm is complete
        sha3_dataout <= data;                                           -- Output RAM words
        ram : sram port map (clk, we, addr, datain, data); 
        r1 : register0 port map (regclk, regreset, d1, q1, mode, regslc, shift);
        r2 : register1 port map (regclk, regreset, d2, q2, mode, regslc, shift);
        dlv : deinterleave port map (wirein=>data, wireup=>deleave_d1, wiredown=>deleave_d2, ctrl=>ctrl);
        
        slcmux : slicemux port map (datain(49 downto 0)=>q1(49 downto 0),datain(99 downto 50)=>q2(49 downto 0), dataout=>sliceout, sel=>regslc);
        slcdemux : slicedemux port map(outslice, regslcin, regslc);
        
        sliceprocessor : sliceproc port map (inslice, outslice, slc, rnd, parclk, byp_ixp, byp_theta);

        laneprocessor : laneproc port map (byp_lane, rhoclk, rhocntr, lanepr, q1, q2, ramaddress, ramdata, ramtrigger, ctrl);

        inslice <= sliceout;

        fasterclock <= not fasterclock after fastPeriod/2;              -- Fast clock for asynchronous computations

        SHA3: process (clk, fasterclock, divider) is                    -- Sensitive only to clocks and frequency divider
            variable k : natural;                                       -- Variables used for looping
            variable loopsize : natural;
            variable innerloop : natural;
            variable modifiedrnd : natural;
        begin
            --- Initialize SRAM ---
            if to_integer(unsigned(counter)) = 0 then
                regreset <= '1';
                addr <= (others => '0');
                datain <= sha3_datain;
            elsif to_integer(unsigned(counter)) < 200 then
                regreset <= '0';
                we <= '1';
                datain <= sha3_datain;
                if falling_edge(clk) then
                    addr <= addr + 1;
                end if;
            --- Load Slice Block 15 ---
            elsif to_integer(unsigned(counter)) = 200 then 
                datain <= (others => 'Z');
                d1(3 downto 0) <= deleave_d1;
                d2(3 downto 0) <= deleave_d2;
                byp_lane <= '1';
                byp_theta <= '1';
                byp_ixp <= '1';
                mode <= '0';
                we <= '0';
                shift <= '0';
                ctrl <= "00";
                sliceblock <= 15;
                iword <= 199-(15-sliceblock);
                addr <= std_logic_vector(to_unsigned(iword, addr'length));
                regslc <= "11";
            elsif to_integer(unsigned(counter)) >= 201 and to_integer(unsigned(counter)) < 213 then
                d1(3 downto 0) <= deleave_d1;
                d2(3 downto 0) <= deleave_d2;     
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
                d1(3 downto 0) <= deleave_d1;
                d2(3 downto 0) <= deleave_d2;
                nword <= (sliceblock rem 2)*4;
                if nword = 4 then
                    ctrl <= "10";
                elsif nword = 0 then
                    ctrl <= "01";
                else
                    ctrl <= "11";
                end if;
                shift <= '1';
                addr <= std_logic_vector(to_unsigned(sliceblock/2, addr'length));
                if clk'event then
                    regclk <= clk;
                end if;
            --- Calculate Parity and store for Slice 63 ---
            elsif to_integer(unsigned(counter)) = 214 then
                regclk <= '0';
                if clk'event then
                    parclk <= clk;
                end if;
            
            --- PERFORM THETA ON ENTIRE STATE ---
            elsif to_integer(unsigned(counter)) >= 215 and to_integer(unsigned(counter)) <= 248+34*15 then
                k := 0;
                loopsize := 34;
                while (k <= 15) loop
                    if to_integer(unsigned(counter)) = 215+loopsize*k then
                        datain <= (others => 'Z');
                        we <= '0';
                        parclk <= '0';
                        regclk <= '0';
                        if not rising_edge(clk) then
                            regreset <= clk;
                        end if;
                    elsif to_integer(unsigned(counter)) = 216+loopsize*k then 
                        d1(3 downto 0) <= deleave_d1;
                        d2(3 downto 0) <= deleave_d2;
                        we <= '0';
                        mode <= '0';
                        regreset <= '0';
                        shift <= '0';
                        ctrl <= "00";
                        sliceblock <= k;
                        regclk <= '0';
                        parclk <= '0';
                        iword <= 199-(15-sliceblock);
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        regslc <= "00";
                    elsif to_integer(unsigned(counter)) >= 215+2+loopsize*k and to_integer(unsigned(counter)) < 215+14+loopsize*k then     -- LOAD SLICE BLOCK
                        d1(3 downto 0) <= deleave_d1;
                        d2(3 downto 0) <= deleave_d2;
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
                        d1(3 downto 0) <= deleave_d1;
                        d2(3 downto 0) <= deleave_d2;
                        nword <= (sliceblock rem 2)*4;
                        byp_theta <= '0';       -- For calculating Theta
                        if nword = 4 then
                            ctrl <= "10";
                        elsif nword = 0 then
                            ctrl <= "01";
                        else
                            ctrl <= "11";
                        end if;
                        shift <= '1';
                        addr <= std_logic_vector(to_unsigned(sliceblock/2, addr'length));
                        if clk'event then
                            regclk <= clk;
                        end if;
                    -- Apply Theta on Block k --
                    elsif to_integer(unsigned(counter)) = 230+loopsize*k then
                        regclk <= '0';
                        regslc <= "00";
                        d1(49 downto 0) <= regslcin(49 downto 0);
                        d2(49 downto 0) <= regslcin(99 downto 50);
                        mode <= '1';
                        shift <= '0';
                    elsif to_integer(unsigned(counter)) <= 234+loopsize*k and to_integer(unsigned(counter)) > 230+loopsize*k then
                        if not rising_edge(clk) then
                            regclk <= clk;      -- Theta current slice and store in register
                            parclk <= clk;
                        end if;
                        if falling_edge(clk) and to_integer(unsigned(regslc)) < 3 then
                            regslc <= regslc + 1;
                        end if;
                        d1(49 downto 0) <= regslcin(49 downto 0);
                        d2(49 downto 0) <= regslcin(99 downto 50);
                    
                    -- SAVE REGISTER CONTENTS TO SRAM
                    elsif to_integer(unsigned(counter)) = 235+loopsize*k then 
                        ctrl <= "00";
                        sliceblock <= k;
                        datain <= ramdata;
                        iword <= 199-(15-sliceblock);
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        rhocntr <= "1100";
                    elsif to_integer(unsigned(counter)) >= 236+loopsize*k and to_integer(unsigned(counter)) < 248+loopsize*k then
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
                    elsif to_integer(unsigned(counter)) = 248+loopsize*k then
                        rhocntr <= (others => '0');
                        we <= '1';
                        nword <= (sliceblock rem 2)*4;
                        datain <= ramdata;
                        if nword = 4 then
                            ctrl <= "10";
                        elsif nword = 0 then
                            ctrl <= "01";
                        else
                            ctrl <= "11";
                        end if;
                        shift <= '1';
                        addr <= std_logic_vector(to_unsigned(sliceblock/2, addr'length));
                    end if;
                    k := k+1;
                end loop;

            -- PERFORM RHO ON ENTIRE STATE --
            elsif to_integer(unsigned(counter)) >= 759 and to_integer(unsigned(counter)) <= 758+66*12 then
                k := 0;
                loopsize := 66;
                while (k <= 11) loop
                    if to_integer(unsigned(counter)) = 759+loopsize*k then     -- LOAD LANE PAIR k
                        divider <= (others => '0');
                        rhocntr <= (others => '0');
                        rhoclk <= '0';
                        byp_lane <= '1';
                        mode <= '0';
                        ctrl <= "00";
                        shift <= '0';
                        d1(3 downto 0) <= deleave_d1;
                        d2(3 downto 0) <= deleave_d2;
                        byp_theta <= '1';
                        regreset <= '1';
                        we <= '0';
                        shift <= '0';
                        ctrl <= "00";
                        offset <= 8+(k)*16 + 15; -- 8 + (lanepair - 1)*16 + 15;
                        addr <= std_logic_vector(to_unsigned(offset, addr'length));
                    elsif to_integer(unsigned(counter)) >= 759+1+loopsize*k and to_integer(unsigned(counter)) < 759+17+loopsize*k then
                        regreset <= '0';
                        d1(3 downto 0) <= deleave_d1;
                        d2(3 downto 0) <= deleave_d2;
                        if not rising_edge(clk) then
                            regclk <= clk;
                        end if;
                        if rising_edge(clk) and to_integer(unsigned(addr)) > 8+k*16 then
                            addr <= addr - 1;
                        end if;
                    elsif to_integer(unsigned(counter)) >= 759+17+loopsize*k and to_integer(unsigned(counter)) <= 824+loopsize*k then
                        rhoclk <= clk;
                        byp_lane <= '0';
                        datain <= ramdata;
                        we <= ramtrigger;
                        addr <= ramaddress;
                        lanepr <= std_logic_vector(to_unsigned(k+1, lanepr'length));
                        if rising_edge(clk) then
                            divider <= std_logic_vector(to_unsigned((to_integer(unsigned(divider)) + 1) rem 3, divider'length));
                        end if;
                        if falling_edge(divider(1)) then
                            rhocntr <= std_logic_vector(to_unsigned((to_integer(unsigned(rhocntr)) + 1) rem 16, rhocntr'length));
                        end if;
                    end if;
                    k := k+1;
                end loop;

            -- PERFORM 23 CONSECUTIVE MODIFIED ROUNDS OF SHA3 --
                -- * Pi, Chi, Iota, Theta operations on entire state
                -- * Rho on entire state
            elsif to_integer(unsigned(counter)) >= 1551 and to_integer(unsigned(counter)) <= 2901+1351*22 then

                loopsize := 1351;
                modifiedrnd := 0;
                
                -- OUTER LOOP FOR REPEATING ROUNDS --
                while (modifiedrnd <= 22) loop

                    --- Load Slice Block 15 ---
                    if to_integer(unsigned(counter)) = 1551+loopsize*modifiedrnd then  -- 200
                        if rising_edge(clk) and to_integer(unsigned(counter)) /= 1551 then
                            rnd <= rnd + 1;
                        end if;
                        if not rising_edge(clk) then
                            regreset <= clk;
                        end if;
                        datain <= (others => 'Z');
                        d1(3 downto 0) <= deleave_d1;
                        d2(3 downto 0) <= deleave_d2;
                        byp_lane <= '1';
                        byp_theta <= '1';
                        byp_ixp <= '0';
                        mode <= '0';
                        we <= '0';
                        shift <= '0';
                        ctrl <= "00";
                        sliceblock <= 15;
                        iword <= 199-(15-sliceblock);
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        regslc <= "11";
                        slc <= std_logic_vector(to_unsigned(63, slc'length));
                    elsif to_integer(unsigned(counter)) >= 1552+loopsize*modifiedrnd and to_integer(unsigned(counter)) < 1564+loopsize*modifiedrnd then
                        d1(3 downto 0) <= deleave_d1;
                        d2(3 downto 0) <= deleave_d2;     
                        if clk'event then
                            regclk <= clk;
                        end if;
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        if rising_edge(clk) then
                            if iword - 16 >= 8 then
                                iword <= iword - 16;
                            end if;
                        end if;
                    elsif to_integer(unsigned(counter)) = 1564+loopsize*modifiedrnd then
                        d1(3 downto 0) <= deleave_d1;
                        d2(3 downto 0) <= deleave_d2;
                        nword <= (sliceblock rem 2)*4;
                        if nword = 4 then
                            ctrl <= "10";
                        elsif nword = 0 then
                            ctrl <= "01";
                        else
                            ctrl <= "11";
                        end if;
                        shift <= '1';
                        addr <= std_logic_vector(to_unsigned(sliceblock/2, addr'length));
                        if clk'event then
                            regclk <= clk;
                        end if;
                    --- Calculate Parity and store for Slice 63 ---
                    elsif to_integer(unsigned(counter)) = 1565+loopsize*modifiedrnd then
                        regclk <= '0';
                        if clk'event then
                            parclk <= clk;
                        end if;

                    -- COMPUTE IOTA, CHI, PI, THETA FOR ENTIRE STATE -- 
                    elsif to_integer(unsigned(counter)) >= 1566+loopsize*modifiedrnd and to_integer(unsigned(counter)) <= 1599+34*15+loopsize*modifiedrnd then
                        
                        k := 0;
                        innerloop := 34;

                        while (k <= 15) loop

                            -- Load Slice Block k --      
                            if to_integer(unsigned(counter)) = 1566+innerloop*k+loopsize*modifiedrnd then
                                datain <= (others => 'Z');
                                we <= '0';
                                parclk <= '0';
                                regclk <= '0';
                                rhoclk <= '0';
                                byp_lane <= '1';
                                byp_ixp <= '1';
                                byp_theta <= '1';
                                if not rising_edge(clk) then
                                    regreset <= clk;
                                end if;
                            elsif to_integer(unsigned(counter)) = 1567+innerloop*k+loopsize*modifiedrnd then 
                                d1(3 downto 0) <= deleave_d1;
                                d2(3 downto 0) <= deleave_d2;
                                we <= '0';
                                mode <= '0';
                                regreset <= '0';
                                shift <= '0';
                                ctrl <= "00";
                                sliceblock <= k;
                                regclk <= '0';
                                parclk <= '0';
                                iword <= 199-(15-sliceblock);
                                addr <= std_logic_vector(to_unsigned(iword, addr'length));
                                regslc <= "00";
                            elsif to_integer(unsigned(counter)) >= 1566+2+innerloop*k+loopsize*modifiedrnd and to_integer(unsigned(counter)) < 1566+14+innerloop*k+loopsize*modifiedrnd then   
                                d1(3 downto 0) <= deleave_d1;
                                d2(3 downto 0) <= deleave_d2;
                                if clk'event then
                                    regclk <= clk;
                                end if;
                                addr <= std_logic_vector(to_unsigned(iword, addr'length));
                                if rising_edge(clk) then
                                    if iword - 16 >= 8 then
                                        iword <= iword - 16;
                                    end if;
                                end if;
                            elsif to_integer(unsigned(counter)) = 1566+14+innerloop*k+loopsize*modifiedrnd then
                                d1(3 downto 0) <= deleave_d1;
                                d2(3 downto 0) <= deleave_d2;
                                nword <= (sliceblock rem 2)*4;
                                if nword = 4 then
                                    ctrl <= "10";
                                elsif nword = 0 then
                                    ctrl <= "01";
                                else
                                    ctrl <= "11";
                                end if;
                                shift <= '1';
                                addr <= std_logic_vector(to_unsigned(sliceblock/2, addr'length));
                                if clk'event then
                                    regclk <= clk;
                                end if;

                            -- Perform Theta on Block k --
                            elsif to_integer(unsigned(counter)) = 1581+innerloop*k+loopsize*modifiedrnd then
                                regclk <= '0';
                                regslc <= "00";
                                byp_ixp <= '0';       -- For computing Iota, Chi, Pi
                                byp_theta <= '0';     -- For computing Theta
                                slc <= std_logic_vector(to_unsigned(sliceblock*4+to_integer(unsigned(regslc)), slc'length));
                                d1(49 downto 0) <= regslcin(49 downto 0);
                                d2(49 downto 0) <= regslcin(99 downto 50);
                                mode <= '1';
                                shift <= '0';
                            elsif to_integer(unsigned(counter)) <= 1585+innerloop*k+loopsize*modifiedrnd and to_integer(unsigned(counter)) > 1581+innerloop*k+loopsize*modifiedrnd then
                                if not rising_edge(clk) then
                                    regclk <= clk;
                                    parclk <= clk;    -- Save parity of current slice
                                end if;
                                if falling_edge(clk) and to_integer(unsigned(regslc)) < 3 then
                                    regslc <= regslc + 1;
                                    slc <= slc + 1;
                                end if;
                                d1(49 downto 0) <= regslcin(49 downto 0);
                                d2(49 downto 0) <= regslcin(99 downto 50);

                            -- SAVE REGISTER CONTENTS TO SRAM
                            elsif to_integer(unsigned(counter)) = 1586+innerloop*k+loopsize*modifiedrnd then
                                parclk <= '0';
                                byp_ixp <= '1';
                                byp_lane <= '1';
                                byp_theta <= '1';
                                ctrl <= "00";
                                sliceblock <= k;
                                datain <= ramdata;
                                iword <= 199-(15-sliceblock);
                                addr <= std_logic_vector(to_unsigned(iword, addr'length));
                                rhocntr <= "1100";
                            elsif to_integer(unsigned(counter)) >= 1587+innerloop*k+loopsize*modifiedrnd and to_integer(unsigned(counter)) < 1599+innerloop*k+loopsize*modifiedrnd then
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
                            elsif to_integer(unsigned(counter)) = 1599+innerloop*k+loopsize*modifiedrnd then
                                rhocntr <= (others => '0');
                                we <= '1';
                                nword <= (sliceblock rem 2)*4;
                                datain <= ramdata;
                                if nword = 4 then
                                    ctrl <= "10";
                                elsif nword = 0 then
                                    ctrl <= "01";
                                else
                                    ctrl <= "11";
                                end if;
                                shift <= '1';
                                addr <= std_logic_vector(to_unsigned(sliceblock/2, addr'length));

                            end if;

                            k := k+1;
                        end loop;

                    -- COMPUTE RHO FOR ENTIRE STATE --
                    elsif to_integer(unsigned(counter)) >= 2110+loopsize*modifiedrnd and to_integer(unsigned(counter)) <= 2109+66*12+loopsize*modifiedrnd then
                        k := 0;
                        innerloop := 66;
                        while (k <= 11) loop               
                            if to_integer(unsigned(counter)) = 2110+innerloop*k+loopsize*modifiedrnd then     -- LOAD LANE PAIR k
                                divider <= (others => '0');
                                rhocntr <= (others => '0');
                                parclk <= '0';
                                rhoclk <= '0';
                                regclk <= '0';
                                byp_theta <= '1';
                                byp_ixp <= '1';
                                byp_lane <= '1';
                                mode <= '0';
                                ctrl <= "00";
                                shift <= '0';
                                d1(3 downto 0) <= deleave_d1;
                                d2(3 downto 0) <= deleave_d2;
                                byp_theta <= '1';
                                regreset <= '1';
                                we <= '0';
                                shift <= '0';
                                ctrl <= "00";
                                offset <= 8+(k)*16 + 15; -- 8 + (lanepair - 1)*16 + 15;
                                addr <= std_logic_vector(to_unsigned(offset, addr'length));
                            elsif to_integer(unsigned(counter)) >= 2110+1+innerloop*k+loopsize*modifiedrnd and to_integer(unsigned(counter)) < 2110+17+innerloop*k+loopsize*modifiedrnd then
                                regreset <= '0';
                                d1(3 downto 0) <= deleave_d1;
                                d2(3 downto 0) <= deleave_d2;
                                if not rising_edge(clk) then
                                    regclk <= clk;
                                end if;
                                if rising_edge(clk) and to_integer(unsigned(addr)) > 8+k*16 then
                                    addr <= addr - 1;
                                end if;
                            elsif to_integer(unsigned(counter)) >= 2110+17+innerloop*k+loopsize*modifiedrnd and to_integer(unsigned(counter)) <= 2175+innerloop*k+loopsize*modifiedrnd then
                                rhoclk <= clk;
                                byp_lane <= '0';
                                datain <= ramdata;
                                we <= ramtrigger;
                                addr <= ramaddress;
                                lanepr <= std_logic_vector(to_unsigned(k+1, lanepr'length));
                                if rising_edge(clk) then
                                    divider <= std_logic_vector(to_unsigned((to_integer(unsigned(divider)) + 1) rem 3, divider'length));
                                end if;
                                if falling_edge(divider(1)) then
                                    rhocntr <= std_logic_vector(to_unsigned((to_integer(unsigned(rhocntr)) + 1) rem 16, rhocntr'length));
                                end if;

                            end if;

                            k := k+1;
                        end loop;
                    end if;

                    modifiedrnd := modifiedrnd + 1;
                end loop;
            
            -- LAST ROUND OF IOTA, CHI, PI --
            elsif to_integer(unsigned(counter)) >= 32624 and to_integer(unsigned(counter)) <= 32657+34*15 then
                    
                k := 0;
                innerloop := 34;

                while (k <= 15) loop

                    -- Load Slice Block k --     
                    if to_integer(unsigned(counter)) = 32624+innerloop*k then
                        rnd <= std_logic_vector(to_unsigned(23, rnd'length));
                        datain <= (others => 'Z');
                        we <= '0';
                        parclk <= '0';
                        regclk <= '0';
                        rhoclk <= '0';
                        byp_lane <= '1';
                        byp_ixp <= '1';
                        byp_theta <= '1';
                        if not rising_edge(clk) then
                            regreset <= clk;
                        end if;
                    elsif to_integer(unsigned(counter)) = 32625+innerloop*k then 
                        d1(3 downto 0) <= deleave_d1;
                        d2(3 downto 0) <= deleave_d2;
                        we <= '0';
                        mode <= '0';
                        regreset <= '0';
                        shift <= '0';
                        ctrl <= "00";
                        sliceblock <= k;
                        regclk <= '0';
                        parclk <= '0';
                        iword <= 199-(15-sliceblock);
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        regslc <= "00";
                    elsif to_integer(unsigned(counter)) >= 32624+2+innerloop*k and to_integer(unsigned(counter)) < 32624+14+innerloop*k then     -- LOAD SLICE BLOCK
                        d1(3 downto 0) <= deleave_d1;
                        d2(3 downto 0) <= deleave_d2;
                        if clk'event then
                            regclk <= clk;
                        end if;
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        if rising_edge(clk) then
                            if iword - 16 >= 8 then
                                iword <= iword - 16;
                            end if;
                        end if;
                    elsif to_integer(unsigned(counter)) = 32624+14+innerloop*k then
                        d1(3 downto 0) <= deleave_d1;
                        d2(3 downto 0) <= deleave_d2;
                        nword <= (sliceblock rem 2)*4;
                        if nword = 4 then
                            ctrl <= "10";
                        elsif nword = 0 then
                            ctrl <= "01";
                        else
                            ctrl <= "11";
                        end if;
                        shift <= '1';
                        addr <= std_logic_vector(to_unsigned(sliceblock/2, addr'length));
                        if clk'event then
                            regclk <= clk;
                        end if;

                    -- Perform IXP on Block k --
                    elsif to_integer(unsigned(counter)) = 32639+innerloop*k then
                        regclk <= '0';
                        regslc <= "00";
                        byp_ixp <= '0';       -- Iota, Chi, Pi
                        byp_theta <= '1';     -- For Bypassing Theta
                        slc <= std_logic_vector(to_unsigned(sliceblock*4+to_integer(unsigned(regslc)), slc'length));
                        d1(49 downto 0) <= regslcin(49 downto 0);
                        d2(49 downto 0) <= regslcin(99 downto 50);
                        mode <= '1';
                        shift <= '0';
                    elsif to_integer(unsigned(counter)) <= 32643+innerloop*k and to_integer(unsigned(counter)) > 32639+innerloop*k then
                        if not rising_edge(clk) then
                            regclk <= clk;
                        end if;
                        if falling_edge(clk) and to_integer(unsigned(regslc)) < 3 then
                            regslc <= regslc + 1;
                            slc <= slc + 1;
                        end if;
                        d1(49 downto 0) <= regslcin(49 downto 0);
                        d2(49 downto 0) <= regslcin(99 downto 50);

                    -- SAVE REGISTER CONTENTS TO SRAM
                    elsif to_integer(unsigned(counter)) = 32644+innerloop*k then
                        parclk <= '0';
                        byp_ixp <= '1';
                        byp_lane <= '1';
                        byp_theta <= '1';
                        ctrl <= "00";
                        sliceblock <= k;
                        datain <= ramdata;
                        iword <= 199-(15-sliceblock);
                        addr <= std_logic_vector(to_unsigned(iword, addr'length));
                        rhocntr <= "1100";
                    elsif to_integer(unsigned(counter)) >= 32645+innerloop*k and to_integer(unsigned(counter)) < 32657+innerloop*k then
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
                    elsif to_integer(unsigned(counter)) = 32657+innerloop*k then
                        rhocntr <= (others => '0');
                        we <= '1';
                        nword <= (sliceblock rem 2)*4;
                        datain <= ramdata;
                        if nword = 4 then
                            ctrl <= "10";
                        elsif nword = 0 then
                            ctrl <= "01";
                        else
                            ctrl <= "11";
                        end if;
                        shift <= '1';
                        addr <= std_logic_vector(to_unsigned(sliceblock/2, addr'length));

                    end if;

                    k := k+1;
                end loop;

            -- END OPERATIONS --
            else
                we <= '0';
                rhoclk <= '0';
                byp_ixp <= '1';
                byp_theta <= '1';
                regclk <= '0';
                parclk <= '0';
                datain <= (others => 'Z');
                byp_lane <= '1';
                regreset <= '1';
                addr <= data_addr;
                End_of_Conversion <= '1';
            end if;
        end process SHA3;

    end architecture arch_sha3_trial;