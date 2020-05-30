-- 200x8 Static RAM block

library ieee;
use ieee.std_logic_1164.all;
use ieee.Numeric_Std.all;

entity sram is port (
    clk : in std_logic;                         -- RAM clock (data is latched if we = '1' and rising edge appears on clock)
    we : in std_logic;                          -- Write enable ('1' enables latching of data)
    addr: in std_logic_vector(8 downto 0);      -- Ram address (0-199 allowed)
    datain: in std_logic_vector(7 downto 0);    -- Input data
    dataout: out std_logic_vector(7 downto 0)   -- Output data
);
end entity sram;

architecture arch_sram of sram is

    type ram_type is array (0 to 199) of std_logic_vector(7 downto 0);      -- Ram internal memory
    signal ram : ram_type;
    
    begin

        RamProcess: process(clk, addr, we, datain) is
            begin
                if rising_edge(clk) then
                    if we = '1' then
                        if addr /= "ZZZZZZZZZ" then     -- Check if address is High Z to prevent metavalues
                            if (to_integer(unsigned(addr))<200) then        -- If we='1' and rising_edge(clk) then non 'Z' logic inputs at datain port are latched
                                if datain(0) /= 'Z' then
                                    ram(to_integer(unsigned(addr)))(0 downto 0) <= datain(0 downto 0);
                                end if;
                                if datain(1) /= 'Z' then
                                    ram(to_integer(unsigned(addr)))(1 downto 1) <= datain(1 downto 1);
                                end if;
                                if datain(2) /= 'Z' then
                                    ram(to_integer(unsigned(addr)))(2 downto 2) <= datain(2 downto 2);
                                end if;
                                if datain(3) /= 'Z' then
                                    ram(to_integer(unsigned(addr)))(3 downto 3) <= datain(3 downto 3);
                                end if;
                                if datain(4) /= 'Z' then
                                    ram(to_integer(unsigned(addr)))(4 downto 4) <= datain(4 downto 4);
                                end if;
                                if datain(5) /= 'Z' then
                                    ram(to_integer(unsigned(addr)))(5 downto 5) <= datain(5 downto 5);
                                end if;
                                if datain(6) /= 'Z' then
                                    ram(to_integer(unsigned(addr)))(6 downto 6) <= datain(6 downto 6);
                                end if;
                                if datain(7) /= 'Z' then
                                    ram(to_integer(unsigned(addr)))(7 downto 7) <= datain(7 downto 7);
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
                if addr /= "ZZZZZZZZZ" then
                    if (to_integer(unsigned(addr))<200) then            -- Output word to dataout port
                        dataout <= ram(to_integer(unsigned(addr)));
                    end if;
                end if;
            end process RamProcess;

    end architecture arch_sram;