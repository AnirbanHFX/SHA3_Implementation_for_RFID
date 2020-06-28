-- 25x50 Slice demultiplexer for writing a slice back to its register positions

library ieee;
use ieee.std_logic_1164.all;

entity slicedemux is port (
    datain : in std_logic_vector(24 downto 0);         -- Slice output from sliceprocessor unit
    dataout : out std_logic_vector(49 downto 0);       -- Output connected to parallel inputs of 64 bit registers
    sel : in std_logic                                 -- Logic for selecting slice (modulo 2)
);
end entity slicedemux;

architecture arch_slicedemux of slicedemux is
    
    begin

        slicedemuxproc : process (sel, datain) is
        begin

            if sel = '0' then
                dataout(0 downto 0) <= datain(0 downto 0);
                dataout(1 downto 1) <= (others => 'Z');
                dataout(3 downto 2) <= datain(2 downto 1);
                dataout(5 downto 4) <= (others => 'Z');
                dataout(7 downto 6) <= datain(4 downto 3);
                dataout(9 downto 8) <= (others => 'Z');
                dataout(11 downto 10) <= datain(6 downto 5);
                dataout(13 downto 12) <= (others => 'Z');
                dataout(15 downto 14) <= datain(8 downto 7);
                dataout(17 downto 16) <= (others => 'Z');
                dataout(19 downto 18) <= datain(10 downto 9);
                dataout(21 downto 20) <= (others => 'Z');
                dataout(23 downto 22) <= datain(12 downto 11);
                dataout(25 downto 24) <= (others => 'Z');
                dataout(27 downto 26) <= datain(14 downto 13);
                dataout(29 downto 28) <= (others => 'Z');
                dataout(31 downto 30) <= datain(16 downto 15);
                dataout(33 downto 32) <= (others => 'Z');
                dataout(35 downto 34) <= datain(18 downto 17);
                dataout(37 downto 36) <= (others => 'Z');
                dataout(39 downto 38) <= datain(20 downto 19);
                dataout(41 downto 40) <= (others => 'Z');
                dataout(43 downto 42) <= datain(22 downto 21);
                dataout(45 downto 44) <= (others => 'Z');
                dataout(47 downto 46) <= datain(24 downto 23);
                dataout(49 downto 48) <= (others => 'Z');
            else
                dataout(0 downto 0) <= (others => 'Z');
                dataout(1 downto 1) <= datain(0 downto 0);
                dataout(3 downto 2) <= (others => 'Z');
                dataout(5 downto 4) <= datain(2 downto 1);
                dataout(7 downto 6) <= (others => 'Z');
                dataout(9 downto 8) <= datain(4 downto 3);
                dataout(11 downto 10) <= (others => 'Z');
                dataout(13 downto 12) <= datain(6 downto 5);
                dataout(15 downto 14) <= (others => 'Z');
                dataout(17 downto 16) <= datain(8 downto 7);
                dataout(19 downto 18) <= (others => 'Z');
                dataout(21 downto 20) <= datain(10 downto 9);
                dataout(23 downto 22) <= (others => 'Z');
                dataout(25 downto 24) <= datain(12 downto 11);
                dataout(27 downto 26) <= (others => 'Z');
                dataout(29 downto 28) <= datain(14 downto 13);
                dataout(31 downto 30) <= (others => 'Z');
                dataout(33 downto 32) <= datain(16 downto 15);
                dataout(35 downto 34) <= (others => 'Z');
                dataout(37 downto 36) <= datain(18 downto 17);
                dataout(39 downto 38) <= (others => 'Z');
                dataout(41 downto 40) <= datain(20 downto 19);
                dataout(43 downto 42) <= (others => 'Z');
                dataout(45 downto 44) <= datain(22 downto 21);
                dataout(47 downto 46) <= (others => 'Z');
                dataout(49 downto 48) <= datain(24 downto 23);
            end if;

        end process slicedemuxproc;

    end architecture arch_slicedemux;