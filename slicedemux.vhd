library ieee;
use ieee.std_logic_1164.all;

entity slicedemux is port (
    datain : in std_logic_vector(24 downto 0);
    dataout : out std_logic_vector(99 downto 0);
    sel : in std_logic_vector(1 downto 0)
);
end entity slicedemux;

architecture arch_slicedemux of slicedemux is
    
    begin

        slicedemuxproc : process (sel, datain) is
        begin

            if sel = "00" then
                dataout(51 downto 50) <= (others => 'Z');

                dataout(0 downto 0) <= datain(0 downto 0);
                dataout(1 downto 1) <= (others => 'Z');

                dataout(2 downto 2) <= datain(1 downto 1);
                dataout(5 downto 3) <= (others => 'Z');

                dataout(52 downto 52) <= datain(2 downto 2);
                dataout(55 downto 53) <= (others => 'Z');

                dataout(6 downto 6) <= datain(3 downto 3);
                dataout(9 downto 7) <= (others => 'Z');

                dataout(56 downto 56) <= datain(4 downto 4);
                dataout(59 downto 57) <= (others => 'Z');

                dataout(10 downto 10) <= datain(5 downto 5);
                dataout(13 downto 11) <= (others => 'Z');

                dataout(60 downto 60) <= datain(6 downto 6);
                dataout(63 downto 61) <= (others => 'Z');

                dataout(14 downto 14) <= datain(7 downto 7);
                dataout(17 downto 15) <= (others => 'Z');

                dataout(64 downto 64) <= datain(8 downto 8);
                dataout(67 downto 65) <= (others => 'Z');

                dataout(18 downto 18) <= datain(9 downto 9);
                dataout(21 downto 19) <= (others => 'Z');

                dataout(68 downto 68) <= datain(10 downto 10);
                dataout(71 downto 69) <= (others => 'Z');

                dataout(22 downto 22) <= datain(11 downto 11);
                dataout(25 downto 23) <= (others => 'Z');

                dataout(72 downto 72) <= datain(12 downto 12);
                dataout(75 downto 73) <= (others => 'Z');

                dataout(26 downto 26) <= datain(13 downto 13);
                dataout(29 downto 27) <= (others => 'Z');

                dataout(76 downto 76) <= datain(14 downto 14);
                dataout(79 downto 77) <= (others => 'Z');

                dataout(30 downto 30) <= datain(15 downto 15);
                dataout(33 downto 31) <= (others => 'Z');

                dataout(80 downto 80) <= datain(16 downto 16);
                dataout(83 downto 81) <= (others => 'Z');

                dataout(34 downto 34) <= datain(17 downto 17);
                dataout(37 downto 35) <= (others => 'Z');

                dataout(84 downto 84) <= datain(18 downto 18);
                dataout(87 downto 85) <= (others => 'Z');

                dataout(38 downto 38) <= datain(19 downto 19);
                dataout(41 downto 39) <= (others => 'Z');

                dataout(88 downto 88) <= datain(20 downto 20);
                dataout(91 downto 89) <= (others => 'Z');

                dataout(42 downto 42) <= datain(21 downto 21);
                dataout(45 downto 43) <= (others => 'Z');

                dataout(92 downto 92) <= datain(22 downto 22);
                dataout(95 downto 93) <= (others => 'Z');

                dataout(46 downto 46) <= datain(23 downto 23);
                dataout(49 downto 47) <= (others => 'Z');

                dataout(96 downto 96) <= datain(24 downto 24);
                dataout(99 downto 97) <= (others => 'Z');
            elsif sel = "01" then
                dataout(2 downto 0) <= (others => 'Z');

                dataout(50 downto 50) <= datain(0 downto 0);
                dataout(52 downto 51) <= (others => 'Z');

                dataout(3 downto 3) <= datain(1 downto 1);
                dataout(6 downto 4) <= (others => 'Z');

                dataout(53 downto 53) <= datain(2 downto 2);
                dataout(56 downto 54) <= (others => 'Z');

                dataout(7 downto 7) <= datain(3 downto 3);
                dataout(10 downto 8) <= (others => 'Z');

                dataout(57 downto 57) <= datain(4 downto 4);
                dataout(60 downto 58) <= (others => 'Z');

                dataout(11 downto 11) <= datain(5 downto 5);
                dataout(14 downto 12) <= (others => 'Z');

                dataout(61 downto 61) <= datain(6 downto 6);
                dataout(64 downto 62) <= (others => 'Z');

                dataout(15 downto 15) <= datain(7 downto 7);
                dataout(18 downto 16) <= (others => 'Z');

                dataout(65 downto 65) <= datain(8 downto 8);
                dataout(68 downto 66) <= (others => 'Z');

                dataout(19 downto 19) <= datain(9 downto 9);
                dataout(22 downto 20) <= (others => 'Z');

                dataout(69 downto 69) <= datain(10 downto 10);
                dataout(72 downto 70) <= (others => 'Z');

                dataout(23 downto 23) <= datain(11 downto 11);
                dataout(26 downto 24) <= (others => 'Z');

                dataout(73 downto 73) <= datain(12 downto 12);
                dataout(76 downto 74) <= (others => 'Z');

                dataout(27 downto 27) <= datain(13 downto 13);
                dataout(30 downto 28) <= (others => 'Z');

                dataout(77 downto 77) <= datain(14 downto 14);
                dataout(80 downto 78) <= (others => 'Z');

                dataout(31 downto 31) <= datain(15 downto 15);
                dataout(34 downto 32) <= (others => 'Z');

                dataout(81 downto 81) <= datain(16 downto 16);
                dataout(84 downto 83) <= (others => 'Z');

                dataout(35 downto 35) <= datain(17 downto 17);
                dataout(38 downto 36) <= (others => 'Z');

                dataout(85 downto 85) <= datain(18 downto 18);
                dataout(88 downto 86) <= (others => 'Z');

                dataout(39 downto 39) <= datain(19 downto 19);
                dataout(42 downto 40) <= (others => 'Z');

                dataout(89 downto 89) <= datain(20 downto 20);
                dataout(92 downto 90) <= (others => 'Z');

                dataout(43 downto 43) <= datain(21 downto 21);
                dataout(46 downto 44) <= (others => 'Z');

                dataout(93 downto 93) <= datain(22 downto 22);
                dataout(96 downto 94) <= (others => 'Z');

                dataout(47 downto 47) <= datain(23 downto 23);
                dataout(49 downto 48) <= (others => 'Z');

                dataout(97 downto 97) <= datain(24 downto 24);
                dataout(99 downto 98) <= (others => 'Z');
            elsif sel = "10" then
                dataout(0 downto 0) <= (others => 'Z');
                dataout(53 downto 50) <= (others => 'Z');

                dataout(1 downto 1) <= datain(0 downto 0);
                dataout(3 downto 2) <= (others => 'Z');

                dataout(4 downto 4) <= datain(1 downto 1);
                dataout(7 downto 5) <= (others => 'Z');

                dataout(54 downto 54) <= datain(2 downto 2);
                dataout(57 downto 55) <= (others => 'Z');

                dataout(8 downto 8) <= datain(3 downto 3);
                dataout(11 downto 9) <= (others => 'Z');

                dataout(58 downto 58) <= datain(4 downto 4);
                dataout(61 downto 59) <= (others => 'Z');

                dataout(12 downto 12) <= datain(5 downto 5);
                dataout(15 downto 13) <= (others => 'Z');

                dataout(62 downto 62) <= datain(6 downto 6);
                dataout(65 downto 63) <= (others => 'Z');

                dataout(16 downto 16) <= datain(7 downto 7);
                dataout(19 downto 17) <= (others => 'Z');

                dataout(66 downto 66) <= datain(8 downto 8);
                dataout(69 downto 67) <= (others => 'Z');

                dataout(20 downto 20) <= datain(9 downto 9);
                dataout(23 downto 21) <= (others => 'Z');

                dataout(70 downto 70) <= datain(10 downto 10);
                dataout(73 downto 71) <= (others => 'Z');
                
                dataout(24 downto 24) <= datain(11 downto 11);
                dataout(27 downto 25) <= (others => 'Z');

                dataout(74 downto 74) <= datain(12 downto 12);
                dataout(77 downto 75) <= (others => 'Z');

                dataout(28 downto 28) <= datain(13 downto 13);
                dataout(31 downto 29) <= (others => 'Z');

                dataout(78 downto 78) <= datain(14 downto 14);
                dataout(81 downto 79) <= (others => 'Z');

                dataout(32 downto 32) <= datain(15 downto 15);
                dataout(35 downto 33) <= (others => 'Z');

                dataout(82 downto 82) <= datain(16 downto 16);
                dataout(85 downto 83) <= (others => 'Z');

                dataout(36 downto 36) <= datain(17 downto 17);
                dataout(39 downto 37) <= (others => 'Z');

                dataout(86 downto 86) <= datain(18 downto 18);
                dataout(89 downto 87) <= (others => 'Z');

                dataout(40 downto 40) <= datain(19 downto 19);
                dataout(43 downto 41) <= (others => 'Z');

                dataout(90 downto 90) <= datain(20 downto 20);
                dataout(93 downto 91) <= (others => 'Z');

                dataout(44 downto 44) <= datain(21 downto 21);
                dataout(47 downto 45) <= (others => 'Z');

                dataout(94 downto 94) <= datain(22 downto 22);
                dataout(97 downto 95) <= (others => 'Z');

                dataout(48 downto 48) <= datain(23 downto 23);
                dataout(49 downto 49) <= (others => 'Z');

                dataout(98 downto 98) <= datain(24 downto 24);
                dataout(99 downto 99) <= (others => 'Z');
            else 
                dataout(4 downto 0) <= (others => 'Z');
                dataout(50 downto 50) <= (others => 'Z');

                dataout(51 downto 51) <= datain(0 downto 0);
                dataout(54 downto 52) <= (others => 'Z');

                dataout(5 downto 5) <= datain(1 downto 1);
                dataout(8 downto 6) <= (others => 'Z');

                dataout(55 downto 55) <= datain(2 downto 2);
                dataout(58 downto 56) <= (others => 'Z');

                dataout(9 downto 9) <= datain(3 downto 3);
                dataout(12 downto 10) <= (others => 'Z');

                dataout(59 downto 59) <= datain(4 downto 4);
                dataout(62 downto 60) <= (others => 'Z');

                dataout(13 downto 13) <= datain(5 downto 5);
                dataout(16 downto 14) <= (others => 'Z');

                dataout(63 downto 63) <= datain(6 downto 6);
                dataout(66 downto 64) <= (others => 'Z');

                dataout(17 downto 17) <= datain(7 downto 7);
                dataout(20 downto 18) <= (others => 'Z');

                dataout(67 downto 67) <= datain(8 downto 8);
                dataout(70 downto 68) <= (others => 'Z');

                dataout(21 downto 21) <= datain(9 downto 9);
                dataout(24 downto 22) <= (others => 'Z');

                dataout(71 downto 71) <= datain(10 downto 10);
                dataout(74 downto 72) <= (others => 'Z');

                dataout(25 downto 25) <= datain(11 downto 11);
                dataout(28 downto 26) <= (others => 'Z');

                dataout(75 downto 75) <= datain(12 downto 12);
                dataout(78 downto 76) <= (others => 'Z');

                dataout(29 downto 29) <= datain(13 downto 13);
                dataout(32 downto 30) <= (others => 'Z');

                dataout(79 downto 79) <= datain(14 downto 14);
                dataout(82 downto 80) <= (others => 'Z');

                dataout(33 downto 33) <= datain(15 downto 15);
                dataout(36 downto 34) <= (others => 'Z');

                dataout(83 downto 83) <= datain(16 downto 16);
                dataout(86 downto 84) <= (others => 'Z');

                dataout(37 downto 37) <= datain(17 downto 17);
                dataout(40 downto 38) <= (others => 'Z');

                dataout(87 downto 87) <= datain(18 downto 18);
                dataout(90 downto 88) <= (others => 'Z');

                dataout(41 downto 41) <= datain(19 downto 19);
                dataout(44 downto 42) <= (others => 'Z');

                dataout(91 downto 91) <= datain(20 downto 20);
                dataout(94 downto 92) <= (others => 'Z');

                dataout(45 downto 45) <= datain(21 downto 21);
                dataout(48 downto 46) <= (others => 'Z');

                dataout(95 downto 95) <= datain(22 downto 22);
                dataout(98 downto 96) <= (others => 'Z');

                dataout(49 downto 49) <= datain(23 downto 23);
                dataout(99 downto 99) <= datain(24 downto 24);
            end if;

        end process slicedemuxproc;

    end architecture arch_slicedemux;