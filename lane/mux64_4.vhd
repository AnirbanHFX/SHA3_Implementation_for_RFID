library ieee;
use ieee.std_logic_1164.all;

entity mux64_4 is 
port(
    datain : in std_logic_vector(63 downto 0);
    dataout : out std_logic_vector(3 downto 0);
    address : in std_logic_vector(3 downto 0);
    bypass_lane : in std_logic          -- '1' for bypassing lane
);
end entity mux64_4;

architecture arch_mux64_4 of mux64_4 is 
begin

    mux64_4_proc : process(datain, address, bypass_lane) is
    begin
        if bypass_lane = '0' then
            if address = "0000" then
                dataout <= datain(3 downto 0);
            elsif address = "0001" then
                dataout <= datain(7 downto 4);
            elsif address = "0010" then
                dataout <= datain(11 downto 8);
            elsif address = "0011" then
                dataout <= datain(15 downto 12);
            elsif address = "0100" then
                dataout <= datain(19 downto 16);
            elsif address = "0101" then
                dataout <= datain(23 downto 20);
            elsif address = "0110" then
                dataout <= datain(27 downto 24);
            elsif address = "0111" then
                dataout <= datain(31 downto 28);
            elsif address = "1000" then
                dataout <= datain(35 downto 32);
            elsif address = "1001" then
                dataout <= datain(39 downto 36);
            elsif address = "1010" then
                dataout <= datain(43 downto 40);
            elsif address = "1011" then
                dataout <= datain(47 downto 44);
            elsif address = "1100" then
                dataout <= datain(51 downto 48);
            elsif address = "1101" then
                dataout <= datain(55 downto 52);
            elsif address = "1110" then
                dataout <= datain(59 downto 56);
            elsif address = "1111" then
                dataout <= datain(63 downto 60);
            else
                dataout <= datain(63 downto 60);
            end if;
        else
            if address = "0000" then
                dataout(1 downto 0) <= datain(1 downto 0);
                dataout(3 downto 2) <= (others => 'Z');
            elsif address = "0001" then
                dataout <= datain(5 downto 2);
            elsif address = "0010" then
                dataout <= datain(9 downto 6);
            elsif address = "0011" then
                dataout <= datain(13 downto 10);
            elsif address = "0100" then
                dataout <= datain(17 downto 14);
            elsif address = "0101" then
                dataout <= datain(21 downto 18);
            elsif address = "0110" then
                dataout <= datain(25 downto 22);
            elsif address = "0111" then
                dataout <= datain(29 downto 26);
            elsif address = "1000" then
                dataout <= datain(33 downto 30);
            elsif address = "1001" then
                dataout <= datain(37 downto 34);
            elsif address = "1010" then
                dataout <= datain(41 downto 38);
            elsif address = "1011" then
                dataout <= datain(45 downto 42);
            elsif address = "1100" then
                dataout <= datain(49 downto 46);
            else
                dataout <= (others => 'Z');
            end if;
        end if;
    end process mux64_4_proc;
end architecture arch_mux64_4;


