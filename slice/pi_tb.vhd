library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pi_tb is
end entity pi_tb;

architecture arch_pi_tb of pi_tb is

    component pi
    port (
        data : in std_logic_vector(24 downto 0);
        outp : out std_logic_vector(24 downto 0)
    );
    end component;

    signal datain : std_logic_vector(24 downto 0) := (others => '0');
    signal dataout : std_logic_vector(24 downto 0);

    begin

        pi1 : pi port map(datain, dataout);

        datain <= "1001101111010010111101111" after 200 ns,
                  (others => '0') after 500 ns;

    end architecture arch_pi_tb; 