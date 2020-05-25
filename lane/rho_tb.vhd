library ieee;
use ieee.std_logic_1164.all;

entity rho_tb is
end entity rho_tb;

architecture arch_rho_tb of rho_tb is

    component rho
    port (
        r1 : in std_logic_vector(3 downto 0);
        r2 : in std_logic_vector(3 downto 0);
        rot1 : in std_logic_vector(1 downto 0);
        rot2 : in std_logic_vector(1 downto 0);
        dir : in std_logic;         -- '0' = right shift, '1' = left shift
        wordout : out std_logic_vector(7 downto 0);
        bypass_rho : in std_logic;
        clk : in std_logic
    );
    end component;

    signal in1, in2 : std_logic_vector(3 downto 0) := (others => '0');
    signal rotate1, rotate2 : std_logic_vector(1 downto 0) := (others => '0');
    signal direction : std_logic := '1';
    signal outp : std_logic_vector(7 downto 0);
    signal byp_rho : std_logic := '1';
    signal clock : std_logic := '0';

    begin

        rho1: rho port map(in1, in2, rotate1, rotate2, direction, outp, byp_rho, clock);

        byp_rho <= '0' after 100 ns;
        rotate1 <= "01" after 100 ns;
        direction <= '0' after 300 ns;
        in1 <= "1100" after 100 ns;
        clock <= '1' after 200 ns,
                 '0' after 300 ns,
                 '1' after 400 ns,
                 '0' after 500 ns,
                 '1' after 600 ns;

    end architecture arch_rho_tb;