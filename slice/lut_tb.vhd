library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity lut_tb is
end entity lut_tb;

architecture behavioral of lut_tb is

    component lut
    port (
        rnd : in std_logic_vector(4 downto 0);
        slc : in std_logic_vector(5 downto 0);
        result : out std_logic
    );
    end component;

    signal roundn : std_logic_vector(4 downto 0) := (0 => '1', others => '0');
    signal slice : std_logic_vector(5 downto 0) := (others => '0');
    signal outp : std_logic;
    signal clk : std_logic := '1';

    begin

        lut1 : lut port map (roundn, slice, outp);

        clk <= not clk after 50 ns;

        testbench : process (clk) is
        begin
            if (rising_edge(clk)) then
                slice <= std_logic_vector(to_unsigned((to_integer(unsigned(slice)) + 1) rem 64, slice'length));
            end if;
            if falling_edge(slice(5)) then
                roundn <= std_logic_vector(to_unsigned((to_integer(unsigned(roundn)) + 1) rem 24, roundn'length));
            end if;
        end process testbench;
    
    end architecture behavioral;

        
