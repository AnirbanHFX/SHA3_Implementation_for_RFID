library ieee;
use ieee.std_logic_1164.all;

entity slicemux is port (
    datain : in std_logic_vector(99 downto 0);
    dataout : out std_logic_vector(24 downto 0);
    sel : in std_logic_vector(1 downto 0)
);
end entity slicemux;

architecture arch_slicemux of slicemux is
    
    begin

        slicemuxproc : process (sel, datain) is
        begin

            if sel = "00" then
                dataout(0 downto 0) <= datain(0 downto 0);
                dataout(1 downto 1) <= datain(2 downto 2);
                dataout(2 downto 2) <= datain(52 downto 52);
                dataout(3 downto 3) <= datain(6 downto 6);
                dataout(4 downto 4) <= datain(56 downto 56);
                dataout(5 downto 5) <= datain(10 downto 10);
                dataout(6 downto 6) <= datain(60 downto 60);
                dataout(7 downto 7) <= datain(14 downto 14);
                dataout(8 downto 8) <= datain(64 downto 64);
                dataout(9 downto 9) <= datain(18 downto 18);
                dataout(10 downto 10) <= datain(68 downto 68);
                dataout(11 downto 11) <= datain(22 downto 22);
                dataout(12 downto 12) <= datain(72 downto 72);
                dataout(13 downto 13) <= datain(26 downto 26);
                dataout(14 downto 14) <= datain(76 downto 76);
                dataout(15 downto 15) <= datain(30 downto 30);
                dataout(16 downto 16) <= datain(80 downto 80);
                dataout(17 downto 17) <= datain(34 downto 34);
                dataout(18 downto 18) <= datain(84 downto 84);
                dataout(19 downto 19) <= datain(38 downto 38);
                dataout(20 downto 20) <= datain(88 downto 88);
                dataout(21 downto 21) <= datain(42 downto 42);
                dataout(22 downto 22) <= datain(92 downto 92);
                dataout(23 downto 23) <= datain(46 downto 46);
                dataout(24 downto 24) <= datain(96 downto 96);
            elsif sel = "01" then
                dataout(0 downto 0) <= datain(50 downto 50);
                dataout(1 downto 1) <= datain(3 downto 3);
                dataout(2 downto 2) <= datain(53 downto 53);
                dataout(3 downto 3) <= datain(7 downto 7);
                dataout(4 downto 4) <= datain(57 downto 57);
                dataout(5 downto 5) <= datain(11 downto 11);
                dataout(6 downto 6) <= datain(61 downto 61);
                dataout(7 downto 7) <= datain(15 downto 15);
                dataout(8 downto 8) <= datain(65 downto 65);
                dataout(9 downto 9) <= datain(19 downto 19);
                dataout(10 downto 10) <= datain(69 downto 69);
                dataout(11 downto 11) <= datain(23 downto 23);
                dataout(12 downto 12) <= datain(73 downto 73);
                dataout(13 downto 13) <= datain(27 downto 27);
                dataout(14 downto 14) <= datain(77 downto 77);
                dataout(15 downto 15) <= datain(31 downto 31);
                dataout(16 downto 16) <= datain(81 downto 81);
                dataout(17 downto 17) <= datain(35 downto 35);
                dataout(18 downto 18) <= datain(85 downto 85);
                dataout(19 downto 19) <= datain(39 downto 39);
                dataout(20 downto 20) <= datain(89 downto 89);
                dataout(21 downto 21) <= datain(43 downto 43);
                dataout(22 downto 22) <= datain(93 downto 93);
                dataout(23 downto 23) <= datain(47 downto 47);
                dataout(24 downto 24) <= datain(97 downto 97);
            elsif sel = "10" then
                dataout(0 downto 0) <= datain(1 downto 1);
                dataout(1 downto 1) <= datain(4 downto 4);
                dataout(2 downto 2) <= datain(54 downto 54);
                dataout(3 downto 3) <= datain(8 downto 8);
                dataout(4 downto 4) <= datain(58 downto 58);
                dataout(5 downto 5) <= datain(12 downto 12);
                dataout(6 downto 6) <= datain(62 downto 62);
                dataout(7 downto 7) <= datain(16 downto 16);
                dataout(8 downto 8) <= datain(66 downto 66);
                dataout(9 downto 9) <= datain(20 downto 20);
                dataout(10 downto 10) <= datain(70 downto 70);
                dataout(11 downto 11) <= datain(24 downto 24);
                dataout(12 downto 12) <= datain(74 downto 74);
                dataout(13 downto 13) <= datain(28 downto 28);
                dataout(14 downto 14) <= datain(78 downto 78);
                dataout(15 downto 15) <= datain(32 downto 32);
                dataout(16 downto 16) <= datain(82 downto 82);
                dataout(17 downto 17) <= datain(36 downto 36);
                dataout(18 downto 18) <= datain(86 downto 86);
                dataout(19 downto 19) <= datain(40 downto 40);
                dataout(20 downto 20) <= datain(90 downto 90);
                dataout(21 downto 21) <= datain(44 downto 44);
                dataout(22 downto 22) <= datain(94 downto 94);
                dataout(23 downto 23) <= datain(48 downto 48);
                dataout(24 downto 24) <= datain(98 downto 98);
            else 
                dataout(0 downto 0) <= datain(51 downto 51);
                dataout(1 downto 1) <= datain(5 downto 5);
                dataout(2 downto 2) <= datain(55 downto 55);
                dataout(3 downto 3) <= datain(9 downto 9);
                dataout(4 downto 4) <= datain(59 downto 59);
                dataout(5 downto 5) <= datain(13 downto 13);
                dataout(6 downto 6) <= datain(63 downto 63);
                dataout(7 downto 7) <= datain(17 downto 17);
                dataout(8 downto 8) <= datain(67 downto 67);
                dataout(9 downto 9) <= datain(21 downto 21);
                dataout(10 downto 10) <= datain(71 downto 71);
                dataout(11 downto 11) <= datain(25 downto 25);
                dataout(12 downto 12) <= datain(75 downto 75);
                dataout(13 downto 13) <= datain(29 downto 29);
                dataout(14 downto 14) <= datain(79 downto 79);
                dataout(15 downto 15) <= datain(33 downto 33);
                dataout(16 downto 16) <= datain(83 downto 83);
                dataout(17 downto 17) <= datain(37 downto 37);
                dataout(18 downto 18) <= datain(87 downto 87);
                dataout(19 downto 19) <= datain(41 downto 41);
                dataout(20 downto 20) <= datain(91 downto 91);
                dataout(21 downto 21) <= datain(45 downto 45);
                dataout(22 downto 22) <= datain(95 downto 95);
                dataout(23 downto 23) <= datain(49 downto 49);
                dataout(24 downto 24) <= datain(99 downto 99);
            end if;

        end process slicemuxproc;

    end architecture arch_slicemux;