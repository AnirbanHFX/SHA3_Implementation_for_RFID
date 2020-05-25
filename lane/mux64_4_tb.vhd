library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity mux64_4_tb is
end entity mux64_4_tb;

architecture arch_mux64_4_tb of mux64_4_tb is

    component mux64_4
    port(
    datain : in std_logic_vector(63 downto 0);
    dataout : out std_logic_vector(3 downto 0);
    address : in std_logic_vector(3 downto 0)
    );
    end component;
    
    signal reg : std_logic_vector(63 downto 0);
    signal outp, addr : std_logic_vector(3 downto 0);

    begin

        a1: mux64_4 port map(reg, outp, addr);

        A: process
        begin
            reg <= x"0123456789ABCDEF";
            addr <= "0000";
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
            wait for 100 ns;
            addr <= addr + 1;
        end process A;
    
    end architecture arch_mux64_4_tb;
        