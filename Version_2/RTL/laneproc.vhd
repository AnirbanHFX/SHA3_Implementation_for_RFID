-- Lane processing unit
-- Routes words to RAM from register

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity laneproc is port(
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
        r : in std_logic_vector(3 downto 0);            -- Output of 64x4 Multiplexer connected to register
        rot : in std_logic_vector(1 downto 0);           -- Shift amount for Barrel Shifter
        dir : in std_logic;                             -- Barrel shifter logic : '0' = right shift, '1' = left shift
        wordout : out std_logic_vector(7 downto 0);     -- Output word from interleaver
        bypass_rho : in std_logic;                      -- Logic '1' to bypass rho operation
        clk : in std_logic;                             -- Clock to Rho registers
        resetreg : in std_logic;                        -- Reset logic for Rho registers
        leaved : in std_logic;                          -- Logic '1' indicates output is to be interleaved and vice versa
        leavectrl : in std_logic_vector(1 downto 0)     -- Control logic to interleaver
    );
    end component;

    type rot_bits is array (0 to 23) of std_logic_vector(5 downto 0);   -- Rotation offsets of each lane, Upper 4 bits used for register addressing (mux), Lower 2 bits for shifting using the Barrel Shifter
    signal rotc : rot_bits := ("000001","000011","000110","001010","001111","010101","011100","100100","101101","110111","000010","001110","011011","101001","111000","001000","011001","101011","111110","010010","100111","111101","010100","101100");

    signal bypass : std_logic;                                                      -- Logic to bypass rho
    signal regout : std_logic_vector(63 downto 0);                                  -- Outputs of main register
    signal regbits : std_logic_vector(3 downto 0);                                  -- Output of register addressing multiplexer
    signal muxaddr : std_logic_vector(3 downto 0) := (others => '0');               -- Address inputs to register addressing multiplexer
    signal rot : std_logic_vector(1 downto 0) := (others => '0');                   -- Shift offset to barrel shifter
    signal rotdir : std_logic := '0';                                               -- Shift direction logic for barrel shifters
    signal outpword : std_logic_vector(7 downto 0);                                 -- Output of interleaver (connected to RAM input)
    signal rhoclk : std_logic := '0';                                               -- Clock for rho registers
    signal state : std_logic_vector(1 downto 0) := "ZZ";                            -- Finite State Machine logic for sequentially computing Rho operation
    signal resetrho : std_logic := '0';                                             -- Logic to reset rho registers
    signal interleaver_ctrl : std_logic_vector(1 downto 0);                         -- Control logic to interleaver
    signal interleaver_leaved : std_logic;                                          -- Interleaver logic - leaved = '0' when writing non-interleaved words and vice versa
    signal start_of_conversion : std_logic := '0';                                  -- 0 initially, 1 after conversion starts

    begin

        bypass <= bypass_lane;
        regout <= reg;
        interleaver_ctrl <= ctrl;
        ramword <= outpword;

        mux : mux64_4 port map(regout, regbits, muxaddr, bypass);

        rhoblock : rho port map(regbits, rot, rotdir, outpword, bypass, rhoclk, resetrho, interleaver_leaved, interleaver_ctrl);

        laneProcess : process(bypass, clk, cntr, state, lane, rhoclk, leaved) is
        begin
            if bypass = '1' then            -- Route slice blocks to RAM when Rho is bypassed
                start_of_conversion <= '0';     -- Signal end of conversion
                muxaddr <= cntr;
                rhoclk <= '0';
                interleaver_leaved <= leaved;
                ramtrig <= '0';
                rotdir <= '0';
                ramaddr <= (others => 'Z');
                resetrho <= '1';
                state <= (others => 'Z');
            else                            -- Route lanes through Rho unit and write them back to RAM
                interleaver_leaved <= '1';
                if cntr'event and cntr <= "0000" then       -- Reset state when counter resets
                    state <= (others => '0');
                elsif clk'event then                        -- Advance state modulo 6 with each clock event
                    state <= std_logic_vector(to_unsigned(((to_integer(unsigned(state))+1) rem 4), state'length));
                end if;
                if lane'event then                      -- Update mux addresses when a new lane is loaded
                    muxaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(to_integer(unsigned(lane)))(5 downto 2)))) rem 16, muxaddr'length));
                    rot <= rotc(to_integer(unsigned(lane)))(1 downto 0);
                end if;
            end if;
            if falling_edge(bypass) then                    -- Update mux addresses and reset state when bypass is set to logic '0'
                state <= "00";
                muxaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(to_integer(unsigned(lane)))(5 downto 2)))) rem 16, muxaddr'length));
            end if;
            if state'event then                 -- Finite State Machine operations
                if state = "00" then               -- State 0: Update mux addresses, shift constants, initialize rho clock, shift direction to '0', ram control inputs, reset rho register, write to ram if start_of_conversion is 1
                    muxaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(rotc(to_integer(unsigned(lane)))(5 downto 2))))+to_integer(unsigned(cntr)) rem 16, muxaddr'length));
                    rot <= rotc(to_integer(unsigned(lane)))(1 downto 0);
                    rhoclk <= '0';
                    rotdir <= '0';
                    if start_of_conversion = '1' then       ------ Previously in state 00
                        ramtrig <= '1';
                    end if;
                    resetrho <= '1';
                elsif state = "01" then            -- State 1: XOR bits of current register section into Rho registers after appropriate shift, set start_of_conversion, update shift constants, reverse shift direction, Select next register section
                    start_of_conversion <= '1';     -- Signal start of conversion
                    resetrho <= '0';
                    ramaddr <= (others => 'Z');
                    ramtrig <= '0';
                    rhoclk <= '1';
                    if rot /= "00" then   
                        muxaddr <= std_logic_vector(to_unsigned((to_integer(unsigned(muxaddr))+1) rem 16, muxaddr'length));
                        rotdir <= '1';
                        rot <= std_logic_vector(to_unsigned(4 - to_integer(unsigned(rot)), rot'length));
                    end if;
                elsif state = "10" then            -- State 2: Address RAM
                    ramtrig <= '0';
                    rhoclk <= '0';
                    
                elsif state = "11" then            -- State 3: XOR bits of next register section into Rho registers provided the shift constant is not 0 (not required in this case)
                    if rot /= "00" then
                        rhoclk <= '1';
                    end if;
                    ramaddr <= std_logic_vector(to_unsigned(8+((to_integer(unsigned(lane))+2)/2-1)*16 + ((to_integer(unsigned(cntr))) rem 16), ramaddr'length));
                    if (8+((to_integer(unsigned(lane)))/2-1)*16 + ((to_integer(unsigned(cntr))) rem 16)) < 8 then
                        interleaver_leaved <= '0';
                    else
                        interleaver_leaved <= '1';
                    end if;
                end if;
            end if;
        end process laneProcess;

    end architecture arch_laneproc;