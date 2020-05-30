-- Bi-directional barrel shifter

library ieee;
use ieee.std_logic_1164.all;

entity barrelshifter is port(
    inbits : in std_logic_vector(3 downto 0);       -- Input bit-string
    outbits : out std_logic_vector(3 downto 0);     -- Output bit-string
    dir : in std_logic;                             -- Direction of shift, '0' = left, '1' = right
    shift : in std_logic_vector(1 downto 0)         -- Number of bits to shift (0-3)
);
end entity barrelshifter;

architecture arch_barrelshifter of barrelshifter is

    begin

        shiftProc : process (inbits, dir, shift) is
        begin 
            if dir = '0' then       -- Left shift logic
                if shift = "00" then
                    outbits <= inbits;
                elsif shift = "01" then
                    outbits(2 downto 0) <= inbits(3 downto 1);
                    outbits(3 downto 3) <= (others => '0');
                elsif shift = "10" then
                    outbits(1 downto 0) <= inbits(3 downto 2);
                    outbits(3 downto 2) <= (others => '0');
                elsif shift = "11" then
                    outbits(0 downto 0) <= inbits(3 downto 3);
                    outbits(3 downto 1) <= (others => '0');
                else
                    outbits <= inbits;
                end if;
            elsif dir = '1' then    -- Right shift logic
                if shift = "00" then
                    outbits <= inbits;
                elsif shift = "01" then
                    outbits(3 downto 1) <= inbits(2 downto 0);
                    outbits(0 downto 0) <= (others => '0');
                elsif shift = "10" then
                    outbits(3 downto 2) <= inbits(1 downto 0);
                    outbits(1 downto 0) <= (others => '0');
                elsif shift = "11" then
                    outbits(3 downto 3) <= inbits(0 downto 0);
                    outbits(2 downto 0) <= (others => '0');
                else
                    outbits <= inbits;
                end if;
            else
                outbits <= inbits;
            end if;
        end process shiftProc;

    end architecture arch_barrelshifter;