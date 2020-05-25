library ieee;
use ieee.std_logic_1164.all;

entity mux64_4 is 
port(
    datain : in std_logic_vector(63 downto 0);
    dataout : out std_logic_vector(3 downto 0);
    address : in std_logic_vector(3 downto 0)
);
end entity mux64_4;

architecture arch_mux64_4 of mux64_4 is 
begin
    with address select
        dataout <=  datain(3 downto 0) when "0000",
                    datain(7 downto 4) when "0001",
                    datain(11 downto 8) when "0010",
                    datain(15 downto 12) when "0011",
                    datain(19 downto 16) when "0100",
                    datain(23 downto 20) when "0101",
                    datain(27 downto 24) when "0110",
                    datain(31 downto 28) when "0111",
                    datain(35 downto 32) when "1000",
                    datain(39 downto 36) when "1001",
                    datain(43 downto 40) when "1010",
                    datain(47 downto 44) when "1011",
                    datain(51 downto 48) when "1100",
                    datain(55 downto 52) when "1101",
                    datain(59 downto 56) when "1110",
                    datain(63 downto 60) when "1111",
                    datain(63 downto 60) when others;
end architecture arch_mux64_4;


