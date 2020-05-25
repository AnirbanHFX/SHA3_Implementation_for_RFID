library ieee;
use ieee.std_logic_1164.all;

entity pi is port (
    data : in std_logic_vector(24 downto 0);
    outp : out std_logic_vector(24 downto 0)
);
end entity pi;

architecture arch_pi of pi is

    begin

        piproc : process (data) is
        begin
            outp(0 downto 0) <= data(0 downto 0);
            outp(1 downto 1) <= data(15 downto 15);
            outp(2 downto 2) <= data(5 downto 5);
            outp(3 downto 3) <= data(20 downto 20);
            outp(4 downto 4) <= data(10 downto 10);
            outp(5 downto 5) <= data(6 downto 6);
            outp(6 downto 6) <= data(21 downto 21);
            outp(7 downto 7) <= data(11 downto 11);
            outp(8 downto 8) <= data(1 downto 1);
            outp(9 downto 9) <= data(16 downto 16);
            outp(10 downto 10) <= data(12 downto 12);
            outp(11 downto 11) <= data(2 downto 2);
            outp(12 downto 12) <= data(17 downto 17);
            outp(13 downto 13) <= data(7 downto 7);
            outp(14 downto 14) <= data(22 downto 22);
            outp(15 downto 15) <= data(18 downto 18);
            outp(16 downto 16) <= data(8 downto 8);
            outp(17 downto 17) <= data(23 downto 23);
            outp(18 downto 18) <= data(13 downto 13);
            outp(19 downto 19) <= data(3 downto 3);
            outp(20 downto 20) <= data(24 downto 24);
            outp(21 downto 21) <= data(14 downto 14);
            outp(22 downto 22) <= data(4 downto 4);
            outp(23 downto 23) <= data(19 downto 19);
            outp(24 downto 24) <= data(9 downto 9);
        end process piproc;

    end architecture arch_pi;