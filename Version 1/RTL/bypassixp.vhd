-- Multiplexer to bypass Iota, Chi, Pi (IXP)

library ieee;
use ieee.std_logic_1164.all;

entity bypassixp is port (
    datain : in std_logic_vector(49 downto 0);      -- (24-0) connected to output of IXP, (49-25) connected to input slice bypassing IXP
    dataout : out std_logic_vector(24 downto 0);    -- Output connected to Parity Unit (Theta block)
    bypass : in std_logic                           -- Output bypasses IXP if bypass == '1'
);
end entity bypassixp;

architecture arch_bypassixp of bypassixp is

    begin

        bypassProc : process (bypass, datain) is
        begin
            if bypass = '0' then
                dataout(24 downto 0) <= datain(49 downto 25);
            else
                dataout(24 downto 0) <= datain(24 downto 0);
            end if;
        end process bypassProc;

    end architecture arch_bypassixp;