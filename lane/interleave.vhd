library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity interleave is port(
    wireout     : out std_logic_vector(7 downto 0);
    wireup      : in std_logic_vector(3 downto 0);
    wiredown    : in std_logic_vector(3 downto 0)
);
end entity interleave;

architecture interleave_arc of interleave is
begin
    wireout(0) <= wireup(0);
    wireout(1) <= wiredown(0);
    wireout(2) <= wireup(1);
    wireout(3) <= wiredown(1);
    wireout(4) <= wireup(2);
    wireout(5) <= wiredown(2);
    wireout(6) <= wireup(3);
    wireout(7) <= wiredown(3);
end architecture interleave_arc;