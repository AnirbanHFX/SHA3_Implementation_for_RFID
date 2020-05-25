library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity deinterleave is port(
    wirein      : in std_logic_vector(7 downto 0);
    wireup      : out std_logic_vector(3 downto 0);
    wiredown    : out std_logic_vector(3 downto 0);
    ctrl        : in std_logic_vector(1 downto 0)
);
end entity deinterleave;----------

architecture deinterleave_arc of deinterleave is
begin
    leave: process (wirein, ctrl) is
    begin
        if ctrl = "00" then
            wireup(0) <= wirein(0);
            wiredown(0) <= wirein(1);
            wireup(1) <= wirein(2);
            wiredown(1) <= wirein(3);
            wireup(2) <= wirein(4);
            wiredown(2) <= wirein(5);
            wireup(3) <= wirein(6);
            wiredown(3) <= wirein(7);
        elsif ctrl = "01" then
            wireup(0) <= wirein(0);
            wiredown(0) <= wirein(1);
            wireup(1) <= wirein(2);
            wiredown(1) <= wirein(3);
            wireup(2) <= 'Z';
            wiredown(2) <= 'Z';
            wireup(3) <= 'Z';
            wiredown(3) <= 'Z';
        elsif ctrl = "10" then
            wireup(0) <= wirein(4);
            wiredown(0) <= wirein(5);
            wireup(1) <= wirein(6);
            wiredown(1) <= wirein(7);
            wireup(2) <= 'Z';
            wiredown(2) <= 'Z';
            wireup(3) <= 'Z';
            wiredown(3) <= 'Z';
        else
            wireup(0) <= 'Z';
            wiredown(0) <= 'Z';
            wireup(1) <= 'Z';
            wiredown(1) <= 'Z';
            wireup(2) <= 'Z';
            wiredown(2) <= 'Z';
            wireup(3) <= 'Z';
            wiredown(3) <= 'Z';
        end if;
    end process leave;
end architecture deinterleave_arc;