-- Parity Register to store parity of previous slice

library ieee;
use ieee.std_logic_1164.all;

entity parityreg is port (
    d : in std_logic_vector(4 downto 0);        -- Register input
    q : out std_logic_vector(4 downto 0);       -- Register output
    clk : in std_logic                          -- Output latches to Input at rising edge of clk
);
end entity parityreg;

architecture arch_parityreg of parityreg is

    begin

        paritystore : process (clk) is 
        begin
            if rising_edge(clk) then
                q <= d;
            end if;
        end process paritystore;

    end architecture arch_parityreg;

-- Unit to compute parities of columns of a slice

library ieee;
use ieee.std_logic_1164.all;

entity parity is port (
    slice : in std_logic_vector(24 downto 0);       -- Input slice from bypass_IXP mux
    paritybits : out std_logic_vector(4 downto 0)   -- Output parity bits for each column
);
end entity parity;

architecture arch_parity of parity is

    begin

        parityProc : process (slice) is
        begin

            paritybits(0) <= slice(0) xor slice(1) xor slice(2) xor slice(3) xor slice(4);
            paritybits(1) <= slice(5) xor slice(6) xor slice(7) xor slice(8) xor slice(9);
            paritybits(2) <= slice(10) xor slice(11) xor slice(12) xor slice(13) xor slice(14);
            paritybits(3) <= slice(15) xor slice(16) xor slice(17) xor slice(18) xor slice(19);
            paritybits(4) <= slice(20) xor slice(21) xor slice(22) xor slice(23) xor slice(24);

        end process parityProc;

    end architecture arch_parity;