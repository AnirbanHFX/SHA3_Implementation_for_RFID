-- Lane processing unit
-- Routes words to RAM from register

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity laneproc is port(
    bypass_lane : in std_logic;                     -- '1' when rho is bypassed and laneproc is used to write slices to RAM, '0' when computing rho
    clk : in std_logic;                             -- Clock input
    cntr : in std_logic_vector(3 downto 0);         -- When computing rho : cntr addresses 16 register sections, when writing slices : cntr addresses 13 register sections
    lanepair : in std_logic_vector(4 downto 0);     -- Index identifying the pair of lanes loaded to registers
    regup : in std_logic_vector(63 downto 0);       -- Output of upper register
    regdwn : in std_logic_vector(63 downto 0);      -- Output of lower register
    ramaddr : out std_logic_vector(8 downto 0);     -- Returns sram address where rho unit contents need to be stored
    ramword : out std_logic_vector(7 downto 0);     -- Interleaver output - connected to input of RAM
    ramtrig : out std_logic;                        -- Write Enable logic of RAM
    ctrl : in std_logic_vector(1 downto 0)          -- Interleaver ctrl logic
);
end entity laneproc;

architecture arch_laneproc of laneproc is

    component mux64_4
    port(
        datain : in std_logic_vector(63 downto 0);      -- Input from register
        dataout : out std_logic_vector(3 downto 0);     -- 4 bit register section (may contain only 2 bits when addressing slices)
        address : in std_logic_vector(3 downto 0);      -- Register section addressing
        bypass_lane : in std_logic                      -- '1' for bypassing lane (register contains a slice), '0' for processing lane (register contains a lane)
    );
    end component;

    component rho
    port (
        r1 : in std_logic_vector(3 downto 0);           -- Output of 64x4 Multiplexer connected to upper register
        r2 : in std_logic_vector(3 downto 0);           -- Output of 64x4 Multiplexer connected to lower register
        rot1 : in std_logic_vector(1 downto 0);         -- Shift amount for Barrel Shifter 1
        rot2 : in std_logic_vector(1 downto 0);         -- Shift amount for Barrel Shifter 2
        dir : in std_logic;                             -- Barrel shifter logic : '0' = right shift, '1' = left shift
        wordout : out std_logic_vector(7 downto 0);     -- Output word from interleaver
        bypass_rho : in std_logic;                      -- Logic '1' to bypass rho operation
        clk : in std_logic;                             -- Clock to Rho registers
        resetreg : in std_logic;                        -- Reset logic for Rho registers
        leavectrl : in std_logic_vector(1 downto 0)     -- Control logic to interleaver
    );
    end component;

    type rot_bits is array (0 to 23) of std_logic_vector(5 downto 0);   -- Rotation offsets of each lane, Upper 4 bits used for register addressing (mux), Lower 2 bits for shifting using the Barrel Shifter
    signal rotc : rot_bits := ("000001","000011","000110","001010","001111","010101","011100","100100","101101","110111","000010","001110","011011","101001","111000","001000","011001","101011","111110","010010","100111","111101","010100","101100");

    signal bypass : std_logic;                                                      -- Logic to bypass rho
    signal reg0, reg1 : std_logic_vector(63 downto 0);                              -- Outputs of upper and lower registers
    signal reg0bits, reg1bits : std_logic_vector(3 downto 0);                       -- Outputs of register addressing multiplexers
    signal upaddr, dwnaddr : std_logic_vector(3 downto 0) := (others => '0');       -- Address inputs to upper and lower register addressing multiplexers
    signal rotup, rotdwn : std_logic_vector(1 downto 0) := (others => '0');         -- Shift offsets to upper and lower barrel shifters
    signal rotdir : std_logic := '0';                                               -- Shift direction logic for barrel shifters
    signal outpword : std_logic_vector(7 downto 0);                                 -- Output of interleaver (connected to RAM input)
    signal rhoclk : std_logic := '0';                                               -- Clock for rho registers
    signal state : std_logic_vector(1 downto 0) := "ZZ";                           -- Finite State Machine logic for sequentially computing Rho operation
    signal resetrho : std_logic := '0';                                             -- Logic to reset rho registers
    signal interleaver_ctrl : std_logic_vector(1 downto 0);                         -- Control logic to interleaver
    signal start_of_conversion : std_logic := '0';                                  -- 0 initially, 1 after conversion starts

    begin

        bypass <= bypass_lane;
        reg0 <= regup;
        reg1 <= regdwn;
        interleaver_ctrl <= ctrl;
        ramword <= outpword;

        muxup : mux64_4 port map(reg0, reg0bits, upaddr, bypass);
        muxdwn : mux64_4 port map(reg1, reg1bits, dwnaddr, bypass);

        rhoblock : rho port map(reg0bits, reg1bits, rotup, rotdwn, rotdir, outpword, bypass, rhoclk, resetrho, interleaver_ctrl);

        laneProcess : process(bypass, clk, cntr, state, lanepair, rhoclk) is
        begin
            if bypass = '1' then            -- Route slice blocks to RAM when Rho is bypassed
                start_of_conversion <= '0';     -- Signal end of conversion
                upaddr <= cntr;
                dwnaddr <= cntr;
                rhoclk <= '0';
                ramtrig <= '0';
                rotdir <= '0';
                ramaddr <= (others => 'Z');
                resetrho <= '1';
                state <= (others => 'Z');
            else                            -- Route lanes through Rho unit and write them back to RAM
                if cntr'event and cntr <= "0000" then       -- Reset state when counter resets
                    state <= (others => '0');
                    -- upaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1))(5 downto 2)))+to_integer(unsigned(cntr))) rem 16, upaddr'length));
                    -- dwnaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1)+1)(5 downto 2)))+to_integer(unsigned(cntr))) rem 16, dwnaddr'length));
                    -- rotup <= rotc(2*(to_integer(unsigned(lanepair))-1))(1 downto 0);
                    -- rotdwn <= rotc(2*(to_integer(unsigned(lanepair))-1)+1)(1 downto 0);
                elsif clk'event then                        -- Advance state modulo 6 with each clock event
                    state <= std_logic_vector(to_unsigned(((to_integer(unsigned(state))+1) rem 4), state'length));
                end if;
                if lanepair'event then                      -- Update mux addresses when a new lanepair is loaded
                    upaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1))(5 downto 2)))) rem 16, upaddr'length));
                    dwnaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1)+1)(5 downto 2)))) rem 16, dwnaddr'length));
                    rotup <= rotc(2*(to_integer(unsigned(lanepair))-1))(1 downto 0);
                    rotdwn <= rotc(2*(to_integer(unsigned(lanepair))-1)+1)(1 downto 0);
                end if;
            end if;
            if falling_edge(bypass) then                    -- Update mux addresses and reset state when bypass is set to logic '0'
                state <= "00";
                upaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1))(5 downto 2)))) rem 16, upaddr'length));
                dwnaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1)+1)(5 downto 2)))) rem 16, dwnaddr'length));
            end if;
            if state'event then                 -- Finite State Machine operations
                if state = "00" then               -- State 0: Update mux addresses, shift constants, initialize rho clock, shift direction to '0', ram control inputs, reset rho register, write to ram if start_of_conversion is 1
                    upaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1))(5 downto 2)))+to_integer(unsigned(cntr))) rem 16, upaddr'length));
                    dwnaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(2*(to_integer(unsigned(lanepair))-1)+1)(5 downto 2)))+to_integer(unsigned(cntr))) rem 16, dwnaddr'length));
                    rotup <= rotc(2*(to_integer(unsigned(lanepair))-1))(1 downto 0);
                    rotdwn <= rotc(2*(to_integer(unsigned(lanepair))-1)+1)(1 downto 0);
                    rhoclk <= '0';
                    rotdir <= '0';
                    if start_of_conversion = '1' then
                        ramtrig <= '1';
                    end if;
                    resetrho <= '1';
                elsif state = "01" then            -- State 1: XOR bits of current register section into Rho registers after appropriate shift, set start_of_conversion, update shift constants, reverse shift direction, Select next register section
                    start_of_conversion <= '1';     -- Signal start of conversion
                    resetrho <= '0';
                    ramaddr <= (others => 'Z');
                    ramtrig <= '0';
                    rhoclk <= '1';
                    if rotup /= "00" and rotdwn /= "00" then   
                        upaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(upaddr))+1) rem 16, upaddr'length));
                        dwnaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(dwnaddr))+1) rem 16, dwnaddr'length));
                        rotdir <= '1';
                        rotup <= std_logic_vector(to_unsigned(4 - to_integer(unsigned(rotup)), rotup'length));
                        rotdwn <= std_logic_vector(to_unsigned(4 - to_integer(unsigned(rotdwn)), rotdwn'length));
                    end if;
                elsif state = "10" then            -- State 2: Address RAM
                    ramtrig <= '0';
                    rhoclk <= '0';
                elsif state = "11" then            -- State 3: XOR bits of next register section into Rho registers provided the shift constant is not 0 (not required in this case)
                    if rotup /= "00" and rotdwn /= "00" then
                        rhoclk <= '1';
                    end if;
                    ramaddr <= std_logic_vector(to_unsigned(8+(to_integer(unsigned(lanepair))-1)*16 + ((to_integer(unsigned(cntr))) rem 16), ramaddr'length));
                end if;
            end if;
        end process laneProcess;

    end architecture arch_laneproc;