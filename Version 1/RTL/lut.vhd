-- 63x1 Multiplexer to return a single bit from the 63 bit words of the Look Up Table

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity muxout is port(
    addr : in std_logic_vector(5 downto 0);     -- Address = Slice index, chooses which bit to return from each 64 bit word
    inp : in std_logic_vector(63 downto 0);     -- 64 bit word from LUT
    outp : out std_logic                        -- Output bit
);
end entity muxout;

architecture arch_mux of muxout is

    begin

        muxproc : process(addr, inp) is
        begin
            if addr(0) /= 'Z' and addr(1) /= 'Z' and addr(2) /= 'Z' and addr(3) /= 'Z' and addr(4) /= 'Z' and addr(5) /= 'Z' then   -- Avoid metavalues
                outp <= inp(to_integer(unsigned(addr)));
            end if;
        end process muxproc;
    
    end architecture arch_mux;

-- Look Up Table storing round constants

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lut is port (
    rnd : in std_logic_vector(4 downto 0);          -- Round index (0-23), serves as address for the lut
    slc : in std_logic_vector(5 downto 0);          -- Slice index (0-63), serves as address for the mux
    result : out std_logic                          -- Output bit, connected to Chi-Iota unit
);
end entity lut;

architecture arch_lut of lut is

    component muxout
    port (
        addr : in std_logic_vector(5 downto 0);     -- Address = Slice index, chooses which bit to return from each 64 bit word
        inp : in std_logic_vector(63 downto 0);     -- 64 bit word from LUT
        outp : out std_logic                        -- Output bit
    );
    end component;

    signal outp : std_logic_vector(63 downto 0);    -- LUT word
    signal outbit : std_logic;                      -- Output bit from mux

    begin

        mux : muxout port map (slc, outp, outbit);  -- Mux instantiation

        lutproc: process(rnd) is        -- Load Round Constants
        begin
            case rnd is
                when "00000" =>
                    outp <= "0000000000000000000000000000000000000000000000000000000000000001";
                when "00001" =>
                    outp <= "0000000000000000000000000000000000000000000000001000000010000010";
                when "00010" =>
                    outp <= "1000000000000000000000000000000000000000000000001000000010001010";
                when "00011" =>
                    outp <= "1000000000000000000000000000000010000000000000001000000000000000";
                when "00100" =>
                    outp <= "0000000000000000000000000000000000000000000000001000000010001011";
                when "00101" =>
                    outp <= "0000000000000000000000000000000010000000000000000000000000000001";
                when "00110" =>
                    outp <= "1000000000000000000000000000000010000000000000001000000010000001";
                when "00111" =>
                    outp <= "1000000000000000000000000000000000000000000000001000000000001001";
                when "01000" =>
                    outp <= "0000000000000000000000000000000000000000000000000000000010001010";
                when "01001" =>
                    outp <= "0000000000000000000000000000000000000000000000000000000010001000";
                when "01010" =>
                    outp <= "0000000000000000000000000000000010000000000000001000000000001001";
                when "01011" =>
                    outp <= "0000000000000000000000000000000010000000000000000000000000001010";
                when "01100" =>
                    outp <= "0000000000000000000000000000000010000000000000001000000010001011";
                when "01101" =>
                    outp <= "1000000000000000000000000000000000000000000000000000000010001011";
                when "01110" =>
                    outp <= "1000000000000000000000000000000000000000000000001000000010001001";
                when "01111" =>
                    outp <= "1000000000000000000000000000000000000000000000001000000000000011";
                when "10000" =>
                    outp <= "1000000000000000000000000000000000000000000000001000000000000010";
                when "10001" =>
                    outp <= "1000000000000000000000000000000000000000000000000000000010000000";
                when "10010" =>
                    outp <= "0000000000000000000000000000000000000000000000001000000000001010";
                when "10011" =>
                    outp <= "1000000000000000000000000000000010000000000000000000000000001010";
                when "10100" =>
                    outp <= "1000000000000000000000000000000010000000000000001000000010000001";
                when "10101" =>
                    outp <= "1000000000000000000000000000000000000000000000001000000010000000";
                when "10110" =>
                    outp <= "0000000000000000000000000000000010000000000000000000000000000001";
                when "10111" =>
                    outp <= "1000000000000000000000000000000010000000000000001000000000001000";
                when others =>
                    outp <= (others => '0');
            end case;
        end process lutproc;

        result <= outbit;

    end architecture arch_lut;