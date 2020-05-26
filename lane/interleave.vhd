library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity interleave is port(
    wireout     : out std_logic_vector(7 downto 0);
    wireup      : in std_logic_vector(3 downto 0);
    wiredown    : in std_logic_vector(3 downto 0);
    ctrl        : in std_logic_vector(1 downto 0)
);
end entity interleave;

architecture interleave_arc of interleave is
begin
    leaver : process (wireup, wiredown, ctrl) is
    begin
        if ctrl = "00" then
            wireout(0) <= wireup(0);
            wireout(1) <= wiredown(0);
            wireout(2) <= wireup(1);
            wireout(3) <= wiredown(1);
            wireout(4) <= wireup(2);
            wireout(5) <= wiredown(2);
            wireout(6) <= wireup(3);
            wireout(7) <= wiredown(3);
        elsif ctrl = "01" then
            wireout(0) <= wireup(0);
            wireout(1) <= wiredown(0);
            wireout(2) <= wireup(1);
            wireout(3) <= wiredown(1);
            wireout(7 downto 4) <= (others => 'Z');
        elsif ctrl = "10" then
            wireout(4) <= wireup(0);
            wireout(5) <= wiredown(0);
            wireout(6) <= wireup(1);
            wireout(7) <= wiredown(1);
            wireout(3 downto 0) <= (others => 'Z');
        else
            wireout(7 downto 0) <= (others => 'Z');
        end if;
    end process leaver;
end architecture interleave_arc;