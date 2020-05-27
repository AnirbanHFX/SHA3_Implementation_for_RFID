library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity sha3_trial_tb is
end entity sha3_trial_tb;

architecture arch_sha3_trial_tb of sha3_trial_tb is

    component sram port (
        clk : in std_logic;
        we : in std_logic;
        addr: in std_logic_vector(8 downto 0);
        datain: in std_logic_vector(7 downto 0);
        dataout: out std_logic_vector(7 downto 0)
    );
    end component;

    component register0 port(
        clk: in std_logic;
        reset: in std_logic;
        d: in std_logic_vector(63 downto 0);
        q: inout std_logic_vector(63 downto 0);
        mode : in std_logic;        -- '0' = serial in, '1' = parallel in
        slc : in std_logic_vector(1 downto 0);      -- Select slice
        shift: in std_logic         -- '0' = shift 4 bits at a time, '1' = shift 2 bits at a time
    );
    end component;

    component register1 port(
        clk: in std_logic;
        reset: in std_logic;
        d: in std_logic_vector(63 downto 0);
        q: inout std_logic_vector(63 downto 0);
        mode : in std_logic;        -- '0' = serial in, '1' = parallel in
        slc : in std_logic_vector(1 downto 0);      -- Select slice
        shift: in std_logic         -- '0' = shift 4 bits at a time, '1' = shift 2 bits at a time
    );
    end component;

    component deinterleave port(
        wirein      : in std_logic_vector(7 downto 0);
        wireup      : out std_logic_vector(3 downto 0);
        wiredown    : out std_logic_vector(3 downto 0);
        ctrl        : in std_logic_vector(1 downto 0)
    );
    end component;

    component slicemux port (
        datain : in std_logic_vector(99 downto 0);
        dataout : out std_logic_vector(24 downto 0);
        sel : in std_logic_vector(1 downto 0)
    );
    end component;

    component slicedemux is port (
        datain : in std_logic_vector(24 downto 0);
        dataout : out std_logic_vector(99 downto 0);
        sel : in std_logic_vector(1 downto 0)
    );
    end component;

    component sliceproc port (
        slicein : in std_logic_vector(24 downto 0);
        sliceout : out std_logic_vector(24 downto 0);
        slice : in std_logic_vector(5 downto 0);    -- For iota
        roundn : in std_logic_vector(4 downto 0);   -- For iota
        storeparity : in std_logic;     -- Rising edge causes parity of current slice to be stored in parity register
        bypass_ixp : in std_logic;      -- Logic 1 bypasses pi, chi, iota
        bypass_theta : in std_logic     -- Logic 1 bypasses theta
    );
    end component;

    component laneproc port (
        bypass_lane : in std_logic;                     -- When used to save slices
        clk : in std_logic;
        cntr : in std_logic_vector(3 downto 0);         -- Counter for 16 subsections of each lane
        lanepair : in std_logic_vector(4 downto 0);
        regup : in std_logic_vector(63 downto 0);
        regdwn : in std_logic_vector(63 downto 0);
        ramaddr : out std_logic_vector(8 downto 0);     -- Returns sram address where rho unit contents need to be stored
        ramword : out std_logic_vector(7 downto 0);
        ramtrig : out std_logic;
        ctrl : in std_logic_vector                      -- Interleaver ctrl logic
    );
    end component;

    type ram_type is array (0 to 199) of std_logic_vector(7 downto 0);
    signal content : ram_type := ("01110101","10011111","11010000","00110101","11011000","11001000","00010011","11101101","01101001","01100011","11101001","00100100","00011000","10010110","11110011","10101110","00110101","01100001","01111111","01000110","01111101","00111110","11100111","00010111","10100001","10110100","00001001","00011111","10101011","11110110","00000011","01011010","10101100","01110100","00011101","00100100","10000011","01110101","10001010","00110001","00001000","01110000","00101011","11010000","11111110","10100011","11001001","11000111","01011110","11100111","01101011","01101111","01101001","01000010","10001000","10001111","00111110","00011011","10010000","01010010","00001101","01110001","10111111","00110101","11000001","11011101","01010010","00101101","01111000","10100101","00001001","01111010","10101000","10010010","00011110","00011110","00011011","10110010","11110000","00011010","11001001","11000011","11111000","11010000","11111101","01100001","00011001","11110110","11010011","10000011","00100111","00110001","10000100","00110001","11010110","01111110","11100100","00100010","00100111","00000000","01110000","11001000","10011001","10000110","10111101","00110010","11010000","01001011","00111000","10101011","01111011","01100111","11101101","01001001","00111110","01100011","01001001","11110110","00001110","10110010","01001010","11111111","00010110","01110101","01010010","01111110","10100101","00111001","10001001","00101100","00000001","00110110","11111010","00111010","00010110","10011000","11011001","00011101","00101000","11000011","00101010","11100111","01001110","11100011","10101101","11111000","11110100","10100010","00100100","10100000","00100000","01100110","11010110","01001010","00010000","00111100","10000011","10011100","10100011","10001110","00001010","01000110","10000111","10111100","01001001","01000001","11001000","00100000","00011100","00110110","11001000","11000011","01010011","11100111","00110011","01000100","01111101","01000001","01111011","01001101","10101000","10000111","01011011","00101001","00111001","10110000","10110000","10100111","11001000","00011110","01000000","11010011","00000111","11011001","01011010","01101000","11010000","01110111","01011010","11100001");
    signal clk : std_logic := '0'; 
    signal fasterclock : std_logic := '0';
    
    -- sram signals --
    signal we : std_logic := '1';
    signal addr : std_logic_vector(8 downto 0) := (others => '0');
    signal data, datain : std_logic_vector(7 downto 0) := "01110101";
    ------------------

    signal counter : std_logic_vector(31 downto 0) := (others => '0');
    --signal countermem : std_logic_vector(31 downto 0) := (others => '0');

    -- register signals --
    signal q1, q2 : std_logic_vector(63 downto 0);
    signal d1, d2 : std_logic_vector(63 downto 0) := (others => '0');
    signal ctrl : std_logic_vector(1 downto 0) := "00";     -- Also used for interleaver and deinterleaver
    signal shift, mode : std_logic := '0';
    signal regclk : std_logic := '0';
    signal regreset: std_logic := '0';
    ----------------------

    -- slice mux/demux signals --
    signal regslc : std_logic_vector(1 downto 0) := "00";
    signal sliceout : std_logic_vector(24 downto  0);
    signal regslcin : std_logic_vector(99 downto 0);
    -----------------------

    -- slice processor signals --
    signal inslice : std_logic_vector(24 downto 0);
    signal outslice : std_logic_vector(24 downto 0);
    signal slc : std_logic_vector(5 downto 0) := (others => '0');
    signal rnd : std_logic_vector(4 downto 0) := (others => '0');
    signal parclk : std_logic := '0';
    signal byp_ixp : std_logic := '1';
    signal byp_theta : std_logic := '1';
    -----------------------------

    -- lane processor signals --
    signal byp_lane : std_logic := '1';
    signal rhoclk : std_logic := '0';
    signal rhocntr : std_logic_vector(3 downto 0) := (others => '0');
    signal lanepr : std_logic_vector(4 downto 0) := (others => '0');
    signal ramaddress : std_logic_vector(8 downto 0);
    signal ramdata : std_logic_vector(7 downto 0);
    signal ramtrigger : std_logic;
    ----------------------------

    -- Deinterleaver Outputs --
    signal deleave_d1, deleave_d2 : std_logic_vector(3 downto 0);
    ---------------------------

    constant Period : time := 100 ns;
    constant fastPeriod : time := 20 ns;

    signal iword, nword, sliceblock, lanepair, offset : natural;

    begin

        ram : sram port map (clk, we, addr, datain, data);
        r1 : register0 port map (regclk, regreset, d1, q1, mode, regslc, shift);
        r2 : register1 port map (regclk, regreset, d2, q2, mode, regslc, shift);
        dlv : deinterleave port map (wirein=>data, wireup=>deleave_d1, wiredown=>deleave_d2, ctrl=>ctrl);
        
        slcmux : slicemux port map (datain(49 downto 0)=>q1(49 downto 0),datain(99 downto 50)=>q2(49 downto 0), dataout=>sliceout, sel=>regslc);
        slcdemux : slicedemux port map(outslice, regslcin, regslc);
        
        sliceprocessor : sliceproc port map (inslice, outslice, slc, rnd, parclk, byp_ixp, byp_theta);

        laneprocessor : laneproc port map (byp_lane, rhoclk, rhocntr, lanepr, q1, q2, ramaddress, ramdata, ramtrigger, ctrl);

        inslice <= sliceout;

        clk <= not clk after Period/2;  -- Global clock
        fasterclock <= not fasterclock after fastPeriod/2;

        count : process (clk) is
        begin
            if (rising_edge(clk)) then
                counter <= counter + 1; -- Control Unit counter
            end if;
        end process count;

        populateRam: process (clk, fasterclock) is
            variable k : natural;
            variable loopsize : natural;
        begin
            --- Initialize SRAM ---
            if to_integer(unsigned(counter)) = 0 then
                regreset <= '1';
                addr <= (others => '0');
            elsif to_integer(unsigned(counter)) < 200 then
                regreset <= '0';
                we <= '1';
                if falling_edge(clk) then
                    addr <= addr + 1;
                    datain <= content(to_integer(unsigned(counter)));
                end if;
            --- Load Slice Block 15 ---
            elsif to_integer(unsigned(counter)) = 200 then 
                datain <= (others => 'Z');
                d1(3 downto 0) <= deleave_d1;
                d2(3 downto 0) <= deleave_d2;
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
            --- Load Slice Blocks ---
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
                    -- Apply Theta on Block 0 --
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
                        end if;
                        parclk <= not clk;      -- Save parity of current slice after theta
                        if falling_edge(clk) and to_integer(unsigned(regslc)) < 3 then
                            regslc <= regslc + 1;
                        end if;
                        d1(49 downto 0) <= regslcin(49 downto 0);
                        d2(49 downto 0) <= regslcin(99 downto 50);
                    
                    -- SAVE REGISTER CONTENTS TO SRAM (CAN TRY THIS OUT LATER)
                    -- RESET REGISTER AFTER THETA 

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
            elsif to_integer(unsigned(counter)) >= 759 and to_integer(unsigned(counter)) < 758+18 then
                k := 0;
                loopsize := 17;
                while (k <=0) loop
                    if to_integer(unsigned(counter)) = 759+loopsize*k then     -- LOAD LANE PAIR k
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
                    end if;
                    k := k+1;
                end loop;
            else
                regreset <= '1';
            end if;
        end process populateRam;

    end architecture arch_sha3_trial_tb;



            -- elsif to_integer(unsigned(counter)) = to_integer(unsigned(countermem))+1 then   -- Store Parity
            --     if clk'event then
            --         if clk = '1' then
            --             parclk <= '1';
            --         else
            --             parclk <= '0';
            --         end if;
            --     end if;
            --     if to_integer(unsigned(counter)) = to_integer(unsigned(countermem))+1 then
            --         countermem <= counter;
            --     end if;