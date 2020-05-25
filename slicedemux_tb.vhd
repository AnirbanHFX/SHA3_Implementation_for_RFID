library ieee;
use ieee.std_logic_1164.all;

entity slicedemux_tb is
end entity slicedemux_tb;

architecture slicedemux_tb_arch of slicedemux_tb is

    component slicedemux port (
        datain : in std_logic_vector(24 downto 0);
        dataout : out std_logic_vector(99 downto 0);
        sel : in std_logic_vector(1 downto 0)
    );
    end component;

    signal data : std_logic_vector(24 downto 0) := "1010101010101010101010101";
    signal dataout : std_logic_vector(99 downto 0);
    signal out0, out1 : std_logic_vector(49 downto 0);
    signal sel : std_logic_vector(1 downto 0) := "00";

    begin

        demuxer : slicedemux port map(data, dataout, sel);

        out0 <= dataout(49 downto 0);
        out1 <= dataout(99 downto 50);

        sel <= "00",
               "01" after 100 ns,
               "10" after 200 ns,
               "11" after 300 ns,
               "00" after 400 ns;

    end architecture slicedemux_tb_arch;