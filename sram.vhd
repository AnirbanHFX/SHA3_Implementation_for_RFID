library ieee;
use ieee.std_logic_1164.all;
use ieee.Numeric_Std.all;

entity sram is port (
    clk : in std_logic;
    we : in std_logic;
    addr: in std_logic_vector(8 downto 0);
    datain: in std_logic_vector(7 downto 0);
    dataout: out std_logic_vector(7 downto 0)
);
end entity sram;

architecture arch_sram of sram is

    type ram_type is array (0 to 199) of std_logic_vector(7 downto 0);
    signal ram : ram_type;
    
    begin

        RamProcess: process(clk, addr, we, datain) is
            begin
                if rising_edge(clk) then
                    if we = '1' then
                        if (to_integer(unsigned(addr))<200) then
                            ram(to_integer(unsigned(addr))) <= datain;
                        end if;
                    end if;
                end if;
                if (to_integer(unsigned(addr))<200) then
                    dataout <= ram(to_integer(unsigned(addr)));
                end if;
            end process RamProcess;

    end architecture arch_sram;