library ieee;
use ieee.std_logic_1164.all;

entity chi_iota_tb is 
end entity chi_iota_tb;

architecture arch_chi_iota_tb of chi_iota_tb is

    component chi_iota
    port (
        data : in std_logic_vector(24 downto 0);
        roundn : in std_logic_vector(4 downto 0);
        slice : in std_logic_vector(5 downto 0);
        outp : out std_logic_vector(24 downto 0);
        xorbitout : out std_logic
    );
    end component;

    signal datain, dataout : std_logic_vector(24 downto 0) := (others => '0');
    signal rnd : std_logic_vector(4 downto 0) := (others => '0');
    signal slice : std_logic_vector(5 downto 0) := (others => '0');
    signal xored : std_logic;

    begin

        chi1: chi_iota port map(datain, rnd, slice, dataout, xored);

        datain <= "1111001010001000011000001" after 10 ns,
                  (others => '0') after 500 ns;

    end architecture arch_chi_iota_tb;