library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity sha3_tb is
end entity sha3_tb;

architecture arch_sha3_tb of sha3_tb is

    component sha3
    port (
        clk : in std_logic;                                 -- Global clock
        sha3_datain : in std_logic_vector(7 downto 0);      -- Input to internal SRAM (must be supplied initial RAM words during counter = 0 to 199)
        counter : in std_logic_vector(15 downto 0);         -- Global counter
        data_addr : in std_logic_vector(8 downto 0);        -- Address input to internal SRAM (Activates after end of conversion)
        sha3_dataout : out std_logic_vector(7 downto 0);    -- Output from internal SRAM
        EOC : out std_logic                                 -- Signal indicating end of SHA3 operations (safe to read from RAM)
    );
    end component;

    signal clock : std_logic := '0';                                    -- Global clock
    signal cntr : std_logic_vector(15 downto 0) := (others => '0');     -- Counter for SHA3 FSM
    signal datain, dataout : std_logic_vector(7 downto 0);              -- Input and output to internal SRAM
    signal addr : std_logic_vector(8 downto 0);                         -- Address lines for internal SRAM
    signal endconversion, startconversion : std_logic := '0';           -- Signals for start and end of conversion

    constant Period : time := 100 ns;

    type ram_type is array (0 to 199) of std_logic_vector(7 downto 0);  -- Storage for initial RAM contents from external file
    signal content : ram_type := (others => "00000000");

    begin

        hash : sha3 port map(clock, datain, cntr, addr, dataout, endconversion);

        fileProc : process (clock) is

            variable inline : line;
            variable word : std_logic_vector(7 downto 0);
            file RAMstate : text;
            variable i : integer;

        begin

            file_open(RAMstate, "externalram.txt", read_mode);      -- Open file containing RAM state

            i := 0;
            readloop : while not (endfile(RAMstate)) loop

                readline(RAMstate, inline);
                read(inline, word);
                content(i) <= word;                                 -- Store RAM word
                if (i < 199) then
                    i := i + 1;
                end if;

            end loop readloop;

            file_close(RAMstate);

        end process fileProc;

        clock <= not clock after Period/2;

        counterProc : process (clock) is
        begin
            -- Begins SHA3 algorithm by incrementing counter
            if rising_edge(clock) and endconversion = '0' and startconversion = '1' then    
                cntr <= cntr + 1;
            end if;
        end process counterProc;

        
        sha3_testbench : process (clock) is
        begin
            if cntr = 0 and endconversion = '0' then
                datain <= content(0);
                startconversion <= '1';     -- Begin algorithm
            elsif cntr < 200 and endconversion = '0' then
                datain <= content(to_integer(unsigned(cntr)));
            end if;
            -- Once endconversion becomes '1', the SHA3 hash function has been computed and the final state is stored in the internal SRAM
            -- The SRAM can then be read word-by-word from the 'dataout' signal by supplying the required address line to the signal 'addr'
        end process sha3_testbench;

    end architecture arch_sha3_tb;