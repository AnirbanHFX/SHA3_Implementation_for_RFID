-- Unit to interleave data to be stored in SRAM

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity interleave is port(
    wireout     : out std_logic_vector(7 downto 0);     -- Interleaved output
    wireup      : in std_logic_vector(3 downto 0);      -- Input from upper register
    wiredown    : in std_logic_vector(3 downto 0);      -- Input from lower register
    ctrl        : in std_logic_vector(1 downto 0)       -- Control logic
);
end entity interleave;

architecture interleave_arc of interleave is
begin
    leaver : process (wireup, wiredown, ctrl) is
    begin

        -- ctrl = "00" is required for writing to interleaved rows (RAM address - 8 to 199)
        -- ctrl = "01" or "10" are required for writing to the non-interleaved row (RAM address - 0 to 7)
        
        -- Let input from upper register be "U3 U2 U1 U0"
        -- Let input from lower register be "L3 L2 L1 L0"

        if ctrl = "00" then                 -- Output = "L3 U3 L2 U2 L1 U1 L0 U0"
            wireout(0) <= wireup(0);
            wireout(1) <= wiredown(0);
            wireout(2) <= wireup(1);
            wireout(3) <= wiredown(1);
            wireout(4) <= wireup(2);
            wireout(5) <= wiredown(2);
            wireout(6) <= wireup(3);
            wireout(7) <= wiredown(3);
        elsif ctrl = "01" then              -- Output = "Z Z Z Z L1 U1 L0 U0"
            wireout(0) <= wireup(0);
            wireout(1) <= wiredown(0);
            wireout(2) <= wireup(1);
            wireout(3) <= wiredown(1);
            wireout(7 downto 4) <= (others => 'Z');
        elsif ctrl = "10" then              -- Output = "L1 U1 L0 U0 Z Z Z Z"
            wireout(4) <= wireup(0);
            wireout(5) <= wiredown(0);
            wireout(6) <= wireup(1);
            wireout(7) <= wiredown(1);
            wireout(3 downto 0) <= (others => 'Z');
        else                                -- Output = "Z Z Z Z Z Z Z Z"
            wireout(7 downto 0) <= (others => 'Z');
        end if;
    end process leaver;
end architecture interleave_arc;