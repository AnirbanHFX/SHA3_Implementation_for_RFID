-- 100x25 multiplexer for selecting a slice from registers

library ieee;
use ieee.std_logic_1164.all;

entity slicemux is port (
    datain : in std_logic_vector(49 downto 0);      -- Input from register outputs
    dataout : out std_logic_vector(24 downto 0);    -- Slice output
    sel : in std_logic                              -- Slice index modulo 2
);
end entity slicemux;

architecture arch_slicemux of slicemux is
    
    begin

        slicemuxproc : process (sel, datain) is
        begin

            if sel = '0' then
                dataout(0 downto 0) <= datain(0 downto 0);
                dataout(2 downto 1) <= datain(3 downto 2);
                dataout(4 downto 3) <= datain(7 downto 6);
                dataout(6 downto 5) <= datain(11 downto 10);
                dataout(8 downto 7) <= datain(15 downto 14);
                dataout(10 downto 9) <= datain(19 downto 18);
                dataout(12 downto 11) <= datain(23 downto 22);
                dataout(14 downto 13) <= datain(27 downto 26);
                dataout(16 downto 15) <= datain(31 downto 30);
                dataout(18 downto 17) <= datain(35 downto 34);
                dataout(20 downto 19) <= datain(39 downto 38);
                dataout(22 downto 21) <= datain(43 downto 42);
                dataout(24 downto 23) <= datain(47 downto 46);
            else
                dataout(0 downto 0) <= datain(1 downto 1);
                dataout(2 downto 1) <= datain(5 downto 4);
                dataout(4 downto 3) <= datain(9 downto 8);
                dataout(6 downto 5) <= datain(13 downto 12);
                dataout(8 downto 7) <= datain(17 downto 16);
                dataout(10 downto 9) <= datain(21 downto 20);
                dataout(12 downto 11) <= datain(25 downto 24);
                dataout(14 downto 13) <= datain(29 downto 28);
                dataout(16 downto 15) <= datain(33 downto 32);
                dataout(18 downto 17) <= datain(37 downto 36);
                dataout(20 downto 19) <= datain(41 downto 40);
                dataout(22 downto 21) <= datain(45 downto 44);
                dataout(24 downto 23) <= datain(49 downto 48);
            end if;

        end process slicemuxproc;

    end architecture arch_slicemux;