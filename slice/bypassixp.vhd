library ieee;
use ieee.std_logic_1164.all;

entity bypassixp is port (
    datain : in std_logic_vector(49 downto 0);
    dataout : out std_logic_vector(24 downto 0);
    bypass : in std_logic
);
end entity bypassixp;

architecture arch_bypassixp of bypassixp is

    begin

        bypassProc : process (bypass, datain) is
        begin
            if bypass = '0' then    -- Bypass
                dataout(24 downto 0) <= datain(49 downto 25);
            else
                dataout(24 downto 0) <= datain(24 downto 0);
            end if;
        end process bypassProc;

    end architecture arch_bypassixp;